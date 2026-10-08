#!/usr/bin/env python3
"""Matrix ↔ Reticulum store-and-forward bridge.

Listens to one Matrix room via the Client-Server API. When the default
route / uplink interface is down, outgoing events are queued. When a local
RNS interface (rnsd or a configured mesh NIC) is available, queued Matrix
events are serialized into RNS broadcast packets.

Loop prevention: every bridged item is stamped with org.rns.bridge
{src, bridge_id, id}. Mesh-originated Matrix events are not re-broadcast,
and packets we already handled are ignored.

This process uses an operator-owned Matrix access token and a local
Reticulum stack. It does not target third-party systems.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Callable, Protocol

ORIGIN_KEY = "org.rns.bridge"
APP_NAME = "matrix"
APP_ASPECT = "rnsbridge"
DEFAULT_CHANNEL = "room-events"
DEFAULT_MTU = 400
DEFAULT_QUEUE = ".matrix-rns-queue"
RNS_IFACE_PREFIXES = ("rns", "rnode", "lora", "nomadnet", "reticulum")

JsonDict = dict[str, Any]


class MatrixTransport(Protocol):
    def sync_room_messages(self, since: str | None) -> tuple[list[JsonDict], str | None]: ...
    def send_room_message(self, content: JsonDict, txn_id: str) -> str: ...


class RnsTransport(Protocol):
    def available(self) -> bool: ...
    def broadcast(self, payload: bytes) -> None: ...
    def poll(self) -> list[bytes]: ...


@dataclass
class BridgeConfig:
    homeserver: str
    access_token: str
    room_id: str
    user_id: str
    bridge_id: str
    queue_dir: Path
    rns_config_dir: str | None = None
    rns_channel: str = DEFAULT_CHANNEL
    poll_interval: float = 2.0
    internet_iface: str | None = None
    rns_iface_prefixes: tuple[str, ...] = RNS_IFACE_PREFIXES
    packet_mtu: int = DEFAULT_MTU


@dataclass
class QueuedItem:
    direction: str  # "to_rns" | "to_matrix"
    event: JsonDict
    queued_at: float = field(default_factory=time.time)


def load_config_from_env(env: dict[str, str] | None = None) -> BridgeConfig:
    src = env if env is not None else os.environ
    required = ("MATRIX_HOMESERVER", "MATRIX_ACCESS_TOKEN", "MATRIX_ROOM_ID", "MATRIX_USER_ID")
    missing = [key for key in required if not src.get(key)]
    if missing:
        raise SystemExit(f"Missing required environment: {', '.join(missing)}")
    prefixes = tuple(
        p.strip().lower()
        for p in src.get("RNS_IFACE_PREFIXES", ",".join(RNS_IFACE_PREFIXES)).split(",")
        if p.strip()
    )
    return BridgeConfig(
        homeserver=src["MATRIX_HOMESERVER"].rstrip("/"),
        access_token=src["MATRIX_ACCESS_TOKEN"],
        room_id=src["MATRIX_ROOM_ID"],
        user_id=src["MATRIX_USER_ID"],
        bridge_id=src.get("BRIDGE_ID") or src["MATRIX_USER_ID"],
        queue_dir=Path(src.get("BRIDGE_QUEUE_DIR") or DEFAULT_QUEUE),
        rns_config_dir=src.get("RNS_CONFIG_DIR"),
        rns_channel=src.get("RNS_CHANNEL") or DEFAULT_CHANNEL,
        poll_interval=float(src.get("BRIDGE_POLL_INTERVAL") or 2.0),
        internet_iface=src.get("INTERNET_IFACE") or None,
        rns_iface_prefixes=prefixes or RNS_IFACE_PREFIXES,
        packet_mtu=int(src.get("RNS_PACKET_MTU") or DEFAULT_MTU),
    )


def event_stamp(event: JsonDict) -> JsonDict | None:
    content = event.get("content")
    if isinstance(content, dict) and isinstance(content.get(ORIGIN_KEY), dict):
        return content[ORIGIN_KEY]
    unsigned = event.get("unsigned")
    if isinstance(unsigned, dict) and isinstance(unsigned.get(ORIGIN_KEY), dict):
        return unsigned[ORIGIN_KEY]
    return None


def is_from_mesh(event: JsonDict) -> bool:
    stamp = event_stamp(event)
    return bool(stamp and stamp.get("src") == "rns")


def is_from_this_bridge(event: JsonDict, bridge_id: str) -> bool:
    stamp = event_stamp(event)
    return bool(stamp and stamp.get("bridge_id") == bridge_id)


def stable_event_id(event: JsonDict) -> str:
    if event.get("event_id"):
        return str(event["event_id"])
    stamp = event_stamp(event)
    if stamp and stamp.get("id"):
        return str(stamp["id"])
    blob = json.dumps(event, sort_keys=True, separators=(",", ":")).encode()
    return "sha256:" + hashlib.sha256(blob).hexdigest()


def compact_matrix_event(event: JsonDict, room_id: str, bridge_id: str) -> JsonDict:
    content = dict(event.get("content") or {})
    content[ORIGIN_KEY] = {
        "src": "matrix",
        "bridge_id": bridge_id,
        "id": stable_event_id(event),
    }
    return {
        "v": 1,
        "room_id": event.get("room_id") or room_id,
        "event_id": event.get("event_id"),
        "sender": event.get("sender"),
        "type": event.get("type") or "m.room.message",
        "origin_server_ts": event.get("origin_server_ts"),
        "content": content,
    }


def serialize_for_rns(event: JsonDict, room_id: str, bridge_id: str, mtu: int = DEFAULT_MTU) -> list[bytes]:
    payload = compact_matrix_event(event, room_id, bridge_id)
    raw = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    if len(raw) <= mtu:
        return [raw]
    frag_id = hashlib.sha256(raw).hexdigest()[:16]
    body_mtu = max(64, mtu - 80)
    chunks = [raw[i : i + body_mtu] for i in range(0, len(raw), body_mtu)]
    packets: list[bytes] = []
    total = len(chunks)
    for index, chunk in enumerate(chunks, start=1):
        envelope = {
            "v": 1,
            "frag": {"id": frag_id, "i": index, "n": total},
            "d": chunk.decode("latin1"),
        }
        packets.append(json.dumps(envelope, separators=(",", ":")).encode("utf-8"))
    return packets


def decode_rns_packet(data: bytes) -> JsonDict | None:
    try:
        parsed = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None
    return parsed if isinstance(parsed, dict) else None


class FragmentAssembler:
    def __init__(self) -> None:
        self._parts: dict[str, dict[int, bytes]] = {}
        self._totals: dict[str, int] = {}

    def ingest(self, packet: JsonDict) -> JsonDict | None:
        frag = packet.get("frag")
        if not frag:
            return packet if packet.get("v") == 1 and "content" in packet else None
        frag_id = str(frag.get("id") or "")
        index = int(frag["i"])
        total = int(frag["n"])
        chunk = str(packet.get("d") or "").encode("latin1")
        self._parts.setdefault(frag_id, {})[index] = chunk
        self._totals[frag_id] = total
        if len(self._parts[frag_id]) < total:
            return None
        raw = b"".join(self._parts[frag_id][i] for i in range(1, total + 1))
        del self._parts[frag_id]
        del self._totals[frag_id]
        try:
            assembled = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return None
        return assembled if isinstance(assembled, dict) else None


def parse_default_route_iface(route_table: str) -> str | None:
    lines = route_table.strip().splitlines()
    if not lines:
        return None
    for line in lines[1:]:
        cols = line.split()
        if len(cols) < 2:
            continue
        iface, destination = cols[0], cols[1]
        if destination == "00000000" and iface and iface != "lo":
            return iface
    return None


def read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return None


def iface_is_up(operstate: str | None) -> bool:
    return (operstate or "").strip().lower() in {"up", "unknown"}


def looks_like_rns_iface(name: str, prefixes: tuple[str, ...]) -> bool:
    lowered = name.lower()
    return any(lowered == prefix or lowered.startswith(prefix) for prefix in prefixes)


class NetworkMonitor:
    """Poll Linux net sysfs / route table. Mesh NICs do not count as internet."""

    def __init__(
        self,
        *,
        proc_route: Path = Path("/proc/net/route"),
        sys_class_net: Path = Path("/sys/class/net"),
        internet_iface: str | None = None,
        rns_prefixes: tuple[str, ...] = RNS_IFACE_PREFIXES,
        rnsd_proc: Path = Path("/proc"),
    ) -> None:
        self.proc_route = proc_route
        self.sys_class_net = sys_class_net
        self.internet_iface = internet_iface
        self.rns_prefixes = rns_prefixes
        self.rnsd_proc = rnsd_proc

    def internet_up(self) -> bool:
        table = read_text(self.proc_route)
        if table is None:
            return False
        iface = self.internet_iface or parse_default_route_iface(table)
        if not iface or looks_like_rns_iface(iface, self.rns_prefixes):
            return False
        state = read_text(self.sys_class_net / iface / "operstate")
        return iface_is_up(state)

    def rns_interface_up(self) -> bool:
        if self.rnsd_running():
            return True
        try:
            names = [p.name for p in self.sys_class_net.iterdir() if p.is_dir()]
        except OSError:
            names = []
        for name in names:
            if not looks_like_rns_iface(name, self.rns_prefixes):
                continue
            if iface_is_up(read_text(self.sys_class_net / name / "operstate")):
                return True
        return False

    def rnsd_running(self) -> bool:
        try:
            for entry in self.rnsd_proc.iterdir():
                if not entry.name.isdigit():
                    continue
                comm = read_text(entry / "comm")
                if comm and comm.strip() == "rnsd":
                    return True
        except OSError:
            return False
        return False


class DiskQueue:
    def __init__(self, directory: Path) -> None:
        self.directory = directory
        self.path = directory / "queue.jsonl"
        self.seen_path = directory / "seen.json"
        self.sync_path = directory / "sync.json"
        self.directory.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self.path.write_text("", encoding="utf-8")

    def load(self) -> list[QueuedItem]:
        items: list[QueuedItem] = []
        for line in self.path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            raw = json.loads(line)
            items.append(QueuedItem(**raw))
        return items

    def save(self, items: list[QueuedItem]) -> None:
        lines = [json.dumps(asdict(item), ensure_ascii=False) for item in items]
        self.path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")

    def enqueue(self, item: QueuedItem) -> None:
        items = self.load()
        items.append(item)
        self.save(items)

    def dequeue_matching(self, direction: str) -> list[QueuedItem]:
        items = self.load()
        kept: list[QueuedItem] = []
        taken: list[QueuedItem] = []
        for item in items:
            if item.direction == direction:
                taken.append(item)
            else:
                kept.append(item)
        self.save(kept)
        return taken

    def load_seen(self) -> set[str]:
        if not self.seen_path.exists():
            return set()
        data = json.loads(self.seen_path.read_text(encoding="utf-8"))
        return set(data) if isinstance(data, list) else set()

    def save_seen(self, seen: set[str]) -> None:
        self.seen_path.write_text(json.dumps(sorted(seen)), encoding="utf-8")

    def load_since(self) -> str | None:
        if not self.sync_path.exists():
            return None
        data = json.loads(self.sync_path.read_text(encoding="utf-8"))
        return data.get("since") if isinstance(data, dict) else None

    def save_since(self, since: str | None) -> None:
        self.sync_path.write_text(json.dumps({"since": since}), encoding="utf-8")


class MatrixHttpClient:
    def __init__(self, config: BridgeConfig, opener: Callable[..., Any] | None = None) -> None:
        self.config = config
        self._opener = opener or urllib.request.urlopen

    def _request(self, method: str, path: str, body: JsonDict | None = None) -> JsonDict:
        url = f"{self.config.homeserver}{path}"
        data = None if body is None else json.dumps(body).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "authorization": f"Bearer {self.config.access_token}",
                "content-type": "application/json",
            },
        )
        try:
            with self._opener(req, timeout=30) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Matrix {method} {path} failed: {exc.code} {detail}") from exc

    def sync_room_messages(self, since: str | None) -> tuple[list[JsonDict], str | None]:
        filt = {
            "room": {
                "rooms": [self.config.room_id],
                "timeline": {"limit": 50, "types": ["m.room.message"]},
            }
        }
        query = {
            "timeout": 0,
            "filter": json.dumps(filt, separators=(",", ":")),
        }
        if since:
            query["since"] = since
        path = "/_matrix/client/v3/sync?" + urllib.parse.urlencode(query)
        payload = self._request("GET", path)
        next_batch = payload.get("next_batch") if isinstance(payload.get("next_batch"), str) else since
        rooms = ((payload.get("rooms") or {}).get("join") or {}).get(self.config.room_id) or {}
        events = ((rooms.get("timeline") or {}).get("events") or [])
        messages = [ev for ev in events if isinstance(ev, dict) and ev.get("type") == "m.room.message"]
        return messages, next_batch

    def send_room_message(self, content: JsonDict, txn_id: str) -> str:
        encoded_room = urllib.parse.quote(self.config.room_id, safe="")
        encoded_txn = urllib.parse.quote(txn_id, safe="")
        path = f"/_matrix/client/v3/rooms/{encoded_room}/send/m.room.message/{encoded_txn}"
        result = self._request("PUT", path, content)
        return str(result.get("event_id") or txn_id)


class RnsBroadcastTransport:
    """Local mesh via the official `rns` package (import RNS)."""

    def __init__(
        self,
        config: BridgeConfig,
        monitor: NetworkMonitor,
        reticulum_factory: Callable[[str | None], Any] | None = None,
    ) -> None:
        self.config = config
        self.monitor = monitor
        self._factory = reticulum_factory
        self._destination = None
        self._inbox: list[bytes] = []
        self._started = False

    def available(self) -> bool:
        if self.monitor.rns_interface_up():
            return True
        return bool(self._started and self._destination is not None)

    def start(self) -> None:
        if self._started:
            return
        rns_mod = self._load_rns()
        if self._factory:
            self._factory(self.config.rns_config_dir)
        else:
            rns_mod.Reticulum(self.config.rns_config_dir)
        dest = rns_mod.Destination(
            None,
            rns_mod.Destination.IN,
            rns_mod.Destination.PLAIN,
            APP_NAME,
            APP_ASPECT,
            self.config.rns_channel,
        )
        dest.set_packet_callback(self._on_packet)
        self._destination = dest
        self._started = True

    def broadcast(self, payload: bytes) -> None:
        if self._destination is None:
            self.start()
        rns_mod = self._load_rns()
        packet = rns_mod.Packet(self._destination, payload)
        packet.send()

    def poll(self) -> list[bytes]:
        items = list(self._inbox)
        self._inbox.clear()
        return items

    def _on_packet(self, data: bytes, _packet: Any) -> None:
        if data:
            self._inbox.append(data)

    @staticmethod
    def _load_rns() -> Any:
        try:
            import RNS  # type: ignore
        except ImportError as exc:
            raise RuntimeError(
                "The reticulum Python package is not installed. Install with: pip install rns"
            ) from exc
        return RNS


class MatrixRnsBridge:
    def __init__(
        self,
        config: BridgeConfig,
        matrix: MatrixTransport,
        rns: RnsTransport,
        monitor: NetworkMonitor,
        queue: DiskQueue,
    ) -> None:
        self.config = config
        self.matrix = matrix
        self.rns = rns
        self.monitor = monitor
        self.queue = queue
        self.assembler = FragmentAssembler()
        self.seen = queue.load_seen()

    def remember(self, item_id: str) -> bool:
        if item_id in self.seen:
            return False
        self.seen.add(item_id)
        if len(self.seen) > 5000:
            self.seen = set(sorted(self.seen)[-2500:])
        self.queue.save_seen(self.seen)
        return True

    def handle_matrix_event(self, event: JsonDict, rns_up: bool) -> str:
        if is_from_mesh(event) or is_from_this_bridge(event, self.config.bridge_id):
            return "loop_skip"
        if event.get("sender") == self.config.user_id and is_from_mesh(event):
            return "loop_skip"
        event_id = stable_event_id(event)
        if not self.remember(f"mx:{event_id}"):
            return "dup_skip"
        if rns_up:
            self._send_to_rns(event)
            return "sent_rns"
        self.queue.enqueue(QueuedItem(direction="to_rns", event=event))
        return "queued_rns"

    def handle_rns_packet(self, data: bytes, internet_up: bool) -> str:
        parsed = decode_rns_packet(data)
        if parsed is None:
            return "invalid"
        assembled = self.assembler.ingest(parsed)
        if assembled is None:
            return "fragment"
        stamp = event_stamp(assembled) or {}
        if stamp.get("src") == "matrix" and stamp.get("bridge_id") == self.config.bridge_id:
            return "loop_skip"
        if stamp.get("src") == "rns" and stamp.get("bridge_id") == self.config.bridge_id:
            return "loop_skip"
        item_id = str(stamp.get("id") or stable_event_id(assembled))
        if not self.remember(f"rns:{item_id}"):
            return "dup_skip"
        content = dict(assembled.get("content") or {})
        content[ORIGIN_KEY] = {
            "src": "rns",
            "bridge_id": self.config.bridge_id,
            "id": item_id,
        }
        outgoing = {
            "msgtype": content.get("msgtype") or "m.text",
            "body": content.get("body") or "",
            ORIGIN_KEY: content[ORIGIN_KEY],
        }
        if internet_up:
            txn = f"rns-{item_id}"[:64]
            self.matrix.send_room_message(outgoing, txn)
            return "sent_matrix"
        self.queue.enqueue(
            QueuedItem(direction="to_matrix", event={"content": outgoing, "event_id": item_id})
        )
        return "queued_matrix"

    def flush_queues(self, *, internet_up: bool, rns_up: bool) -> dict[str, int]:
        stats = {"to_rns": 0, "to_matrix": 0}
        if rns_up:
            for item in self.queue.dequeue_matching("to_rns"):
                self._send_to_rns(item.event)
                stats["to_rns"] += 1
        if internet_up:
            for item in self.queue.dequeue_matching("to_matrix"):
                content = item.event.get("content") or {}
                txn = f"q-{stable_event_id(item.event)}"[:64]
                self.matrix.send_room_message(content, txn)
                stats["to_matrix"] += 1
        return stats

    def tick(self) -> dict[str, Any]:
        internet_up = self.monitor.internet_up()
        rns_up = self.rns.available()
        actions: list[str] = []

        if internet_up:
            since = self.queue.load_since()
            events, next_batch = self.matrix.sync_room_messages(since)
            self.queue.save_since(next_batch)
            for event in events:
                actions.append(self.handle_matrix_event(event, rns_up=rns_up))
        else:
            actions.append("internet_down")

        if rns_up:
            for packet in self.rns.poll():
                actions.append(self.handle_rns_packet(packet, internet_up=internet_up))
        else:
            actions.append("rns_down")

        flushed = self.flush_queues(internet_up=internet_up, rns_up=rns_up)
        return {
            "internet_up": internet_up,
            "rns_up": rns_up,
            "actions": actions,
            "flushed": flushed,
        }

    def _send_to_rns(self, event: JsonDict) -> None:
        for packet in serialize_for_rns(
            event,
            self.config.room_id,
            self.config.bridge_id,
            self.config.packet_mtu,
        ):
            self.rns.broadcast(packet)


def run_loop(bridge: MatrixRnsBridge, interval: float) -> None:
    while True:
        result = bridge.tick()
        print(json.dumps(result), flush=True)
        time.sleep(interval)


def build_bridge(config: BridgeConfig) -> MatrixRnsBridge:
    monitor = NetworkMonitor(
        internet_iface=config.internet_iface,
        rns_prefixes=config.rns_iface_prefixes,
    )
    matrix = MatrixHttpClient(config)
    rns = RnsBroadcastTransport(config, monitor)
    if monitor.rns_interface_up():
        try:
            rns.start()
        except RuntimeError as exc:
            print(f"[bridge] RNS start deferred: {exc}", file=sys.stderr)
    queue = DiskQueue(config.queue_dir)
    return MatrixRnsBridge(config, matrix, rns, monitor, queue)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Matrix ↔ Reticulum offline bridge")
    parser.add_argument("--once", action="store_true", help="Run a single poll cycle and exit")
    args = parser.parse_args(argv)
    config = load_config_from_env()
    bridge = build_bridge(config)
    if args.once:
        print(json.dumps(bridge.tick()))
        return 0
    run_loop(bridge, config.poll_interval)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
