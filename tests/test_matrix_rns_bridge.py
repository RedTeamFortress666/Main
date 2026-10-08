#!/usr/bin/env python3
"""Tests for matrix_rns_bridge.py (no live Matrix or rnsd required)."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import matrix_rns_bridge as bridge  # noqa: E402


ROUTE_UP = """Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\tMask\tMTU\tWindow\tIRTT
eth0\t00000000\t010011AC\t0003\t0\t0\t100\t00000000\t0\t0\t0
eth0\t000011AC\t00000000\t0001\t0\t0\t100\t00FFFFFF\t0\t0\t0
"""

ROUTE_RNS_DEFAULT = """Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\tMask\tMTU\tWindow\tIRTT
rns0\t00000000\t00000000\t0003\t0\t0\t100\t00000000\t0\t0\t0
"""

ROUTE_DOWN = """Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\tMask\tMTU\tWindow\tIRTT
eth0\t000011AC\t00000000\t0001\t0\t0\t100\t00FFFFFF\t0\t0\t0
"""


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


class FakeMatrix:
    def __init__(self) -> None:
        self.pending: list[dict] = []
        self.sent: list[dict] = []
        self.since = "s0"

    def sync_room_messages(self, since: str | None):
        events = list(self.pending)
        self.pending.clear()
        nxt = "s1" if since != "s1" else "s2"
        return events, nxt

    def send_room_message(self, content: dict, txn_id: str) -> str:
        self.sent.append({"content": content, "txn_id": txn_id})
        return f"$sent-{txn_id}"


class FakeRns:
    def __init__(self, up: bool = True) -> None:
        self.up = up
        self.sent: list[bytes] = []
        self.inbox: list[bytes] = []

    def available(self) -> bool:
        return self.up

    def broadcast(self, payload: bytes) -> None:
        self.sent.append(payload)

    def poll(self) -> list[bytes]:
        items = list(self.inbox)
        self.inbox.clear()
        return items


def sample_config(tmp: Path) -> bridge.BridgeConfig:
    return bridge.BridgeConfig(
        homeserver="https://matrix.example",
        access_token="syt_test",
        room_id="!room:example",
        user_id="@bridge:example",
        bridge_id="bridge-1",
        queue_dir=tmp / "queue",
        packet_mtu=120,
    )


def sample_event(event_id: str = "$aaa", body: str = "hello mesh") -> dict:
    return {
        "event_id": event_id,
        "sender": "@alice:example",
        "type": "m.room.message",
        "room_id": "!room:example",
        "origin_server_ts": 1,
        "content": {"msgtype": "m.text", "body": body},
    }


class NetworkMonitorTests(unittest.TestCase):
    def test_internet_up_requires_non_mesh_default_route(self) -> None:
        from tempfile import TemporaryDirectory

        td = TemporaryDirectory()
        self.addCleanup(td.cleanup)
        root = Path(td.name)
        write(root / "route", ROUTE_UP)
        write(root / "net" / "eth0" / "operstate", "up\n")
        mon = bridge.NetworkMonitor(
            proc_route=root / "route",
            sys_class_net=root / "net",
            rnsd_proc=root / "proc",
        )
        self.assertTrue(mon.internet_up())

        write(root / "route", ROUTE_DOWN)
        self.assertFalse(mon.internet_up())

        write(root / "route", ROUTE_RNS_DEFAULT)
        write(root / "net" / "rns0" / "operstate", "up\n")
        self.assertFalse(mon.internet_up())
        self.assertTrue(mon.rns_interface_up())

    def test_rnsd_comm_counts_as_available(self) -> None:
        from tempfile import TemporaryDirectory

        td = TemporaryDirectory()
        self.addCleanup(td.cleanup)
        root = Path(td.name)
        write(root / "proc" / "42" / "comm", "rnsd\n")
        mon = bridge.NetworkMonitor(
            proc_route=root / "missing-route",
            sys_class_net=root / "net",
            rnsd_proc=root / "proc",
        )
        self.assertTrue(mon.rnsd_running())
        self.assertTrue(mon.rns_interface_up())


class SerializeTests(unittest.TestCase):
    def test_round_trip_and_fragmentation(self) -> None:
        event = sample_event(body="x" * 400)
        packets = bridge.serialize_for_rns(event, "!room:example", "bridge-1", mtu=120)
        self.assertGreater(len(packets), 1)
        assembler = bridge.FragmentAssembler()
        assembled = None
        for pkt in packets:
            parsed = bridge.decode_rns_packet(pkt)
            assert parsed is not None
            assembled = assembler.ingest(parsed)
        self.assertIsNotNone(assembled)
        assert assembled is not None
        self.assertEqual(assembled["content"]["body"], "x" * 400)
        self.assertEqual(assembled["content"][bridge.ORIGIN_KEY]["src"], "matrix")
        self.assertNotIn("PrivateKey", json.dumps(assembled))


class BridgeLoopAndQueueTests(unittest.TestCase):
    def setUp(self) -> None:
        from tempfile import TemporaryDirectory

        self.td = TemporaryDirectory()
        self.addCleanup(self.td.cleanup)
        self.tmp = Path(self.td.name)
        self.config = sample_config(self.tmp)
        self.matrix = FakeMatrix()
        self.rns = FakeRns(up=True)
        self.monitor = bridge.NetworkMonitor(
            proc_route=self.tmp / "route",
            sys_class_net=self.tmp / "net",
            rnsd_proc=self.tmp / "proc",
        )
        write(self.tmp / "route", ROUTE_UP)
        write(self.tmp / "net" / "eth0" / "operstate", "up\n")
        self.queue = bridge.DiskQueue(self.config.queue_dir)
        self.bridge = bridge.MatrixRnsBridge(
            self.config, self.matrix, self.rns, self.monitor, self.queue
        )

    def test_offline_queues_matrix_then_flushes_to_rns(self) -> None:
        write(self.tmp / "route", ROUTE_DOWN)
        self.rns.up = False
        status = self.bridge.handle_matrix_event(sample_event(), rns_up=False)
        self.assertEqual(status, "queued_rns")
        self.assertEqual(len(self.queue.load()), 1)

        self.rns.up = True
        flushed = self.bridge.flush_queues(internet_up=False, rns_up=True)
        self.assertEqual(flushed["to_rns"], 1)
        self.assertGreaterEqual(len(self.rns.sent), 1)
        assembler = bridge.FragmentAssembler()
        assembled = None
        for raw in self.rns.sent:
            parsed = bridge.decode_rns_packet(raw)
            assert parsed is not None
            assembled = assembler.ingest(parsed) or assembled
        self.assertIsNotNone(assembled)
        assert assembled is not None
        self.assertEqual(assembled["content"][bridge.ORIGIN_KEY]["src"], "matrix")

    def test_mesh_origin_is_not_re_broadcast(self) -> None:
        event = sample_event("$from-mesh")
        event["content"][bridge.ORIGIN_KEY] = {
            "src": "rns",
            "bridge_id": "bridge-1",
            "id": "pkt-1",
        }
        self.assertEqual(self.bridge.handle_matrix_event(event, rns_up=True), "loop_skip")
        self.assertEqual(self.rns.sent, [])

    def test_own_broadcast_is_not_injected_back_to_matrix(self) -> None:
        packets = bridge.serialize_for_rns(sample_event("$local"), "!room:example", "bridge-1")
        status = self.bridge.handle_rns_packet(packets[0], internet_up=True)
        self.assertEqual(status, "loop_skip")
        self.assertEqual(self.matrix.sent, [])

    def test_foreign_mesh_packet_goes_to_matrix_with_rns_stamp(self) -> None:
        foreign = {
            "v": 1,
            "room_id": "!room:example",
            "event_id": "$other",
            "sender": "@bob:mesh",
            "type": "m.room.message",
            "content": {
                "msgtype": "m.text",
                "body": "from mesh",
                bridge.ORIGIN_KEY: {"src": "rns", "bridge_id": "other-bridge", "id": "pkt-9"},
            },
        }
        status = self.bridge.handle_rns_packet(json.dumps(foreign).encode(), internet_up=True)
        self.assertEqual(status, "sent_matrix")
        self.assertEqual(self.matrix.sent[0]["content"][bridge.ORIGIN_KEY]["src"], "rns")
        self.assertEqual(self.matrix.sent[0]["content"]["body"], "from mesh")

    def test_tick_syncs_when_online_and_skips_duplicates(self) -> None:
        self.matrix.pending.append(sample_event("$dup"))
        first = self.bridge.tick()
        self.assertIn("sent_rns", first["actions"])
        self.matrix.pending.append(sample_event("$dup"))
        second = self.bridge.tick()
        self.assertIn("dup_skip", second["actions"])

    def test_rns_packet_queued_when_internet_down(self) -> None:
        foreign = {
            "v": 1,
            "content": {
                "msgtype": "m.text",
                "body": "store me",
                bridge.ORIGIN_KEY: {"src": "rns", "bridge_id": "peer", "id": "pkt-q"},
            },
        }
        status = self.bridge.handle_rns_packet(json.dumps(foreign).encode(), internet_up=False)
        self.assertEqual(status, "queued_matrix")
        flushed = self.bridge.flush_queues(internet_up=True, rns_up=False)
        self.assertEqual(flushed["to_matrix"], 1)
        self.assertEqual(self.matrix.sent[0]["content"]["body"], "store me")


class ConfigTests(unittest.TestCase):
    def test_missing_env_exits(self) -> None:
        with self.assertRaises(SystemExit):
            bridge.load_config_from_env({})


if __name__ == "__main__":
    unittest.main()
