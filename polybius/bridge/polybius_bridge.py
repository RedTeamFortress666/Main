#!/usr/bin/env python3
"""PØLYBĪUS Reticulum bridge.

Runs a Reticulum (RNS) + LXMF node and exposes a small localhost WebSocket API
so the Flutter app can relay emoji ciphertext over a Reticulum mesh without
needing a Dart RNS implementation (there isn't one).

    pip install -r requirements.txt
    python3 polybius_bridge.py            # ws://127.0.0.1:8765

WebSocket protocol (JSON, one object per frame):
  server -> client on connect:   {"type": "identity", "address": "<hex hash>"}
  client -> server to transmit:  {"type": "send", "to": "<hex hash>", "payload": "<ciphertext>"}
  server -> client on receive:   {"type": "message", "from": "<hex hash>", "payload": "<ciphertext>"}
  server -> client on problem:   {"type": "error", "detail": "..."}

The `payload` is opaque to the bridge — pass the app's emoji ciphertext through
as-is. The bridge never sees plaintext or the cipher mapping.

NOTE (scaffold): sending requires a known path to the recipient. In Reticulum
that means the recipient's node has announced and this node has recalled its
identity. Peers should announce (see `--announce`) and exchange destination
hashes (e.g. via the app's SYNC QR). Path discovery/retries are intentionally
minimal here and are the main thing to harden for production.
"""
import argparse
import asyncio
import json
import os
import threading

import RNS
import LXMF
import websockets

APP_NAME = "polybius"
DEFAULT_STORAGE = os.path.expanduser("~/.polybius_bridge")

_clients = set()
_loop = None  # asyncio loop, set in main()


def _broadcast(obj):
    """Thread-safe push of a JSON object to all connected websocket clients."""
    if _loop is None:
        return
    data = json.dumps(obj)
    for ws in list(_clients):
        asyncio.run_coroutine_threadsafe(ws.send(data), _loop)


class Bridge:
    def __init__(self, configdir=None, storage=DEFAULT_STORAGE,
                 announce_on_start=False):
        os.makedirs(storage, exist_ok=True)
        self.reticulum = RNS.Reticulum(configdir=configdir)

        id_path = os.path.join(storage, "identity")
        if os.path.isfile(id_path):
            self.identity = RNS.Identity.from_file(id_path)
        else:
            self.identity = RNS.Identity()
            self.identity.to_file(id_path)

        self.router = LXMF.LXMRouter(
            identity=self.identity, storagepath=storage
        )
        self.local = self.router.register_delivery_identity(
            self.identity, display_name=APP_NAME
        )
        self.router.register_delivery_callback(self._on_lxmf)
        self.address = RNS.hexrep(self.local.hash, delimit=False)
        RNS.log(f"Polybius bridge address: {self.address}")
        if announce_on_start:
            self.local.announce()

    def _on_lxmf(self, message):
        try:
            payload = message.content.decode("utf-8", errors="replace")
            source = RNS.hexrep(message.source_hash, delimit=False)
        except Exception as e:  # noqa: BLE001
            _broadcast({"type": "error", "detail": f"decode: {e}"})
            return
        _broadcast({"type": "message", "from": source, "payload": payload})

    def send(self, to_hex, payload):
        try:
            dest_hash = bytes.fromhex(to_hex)
        except ValueError:
            _broadcast({"type": "error", "detail": "bad destination hash"})
            return
        recipient = RNS.Identity.recall(dest_hash)
        if recipient is None:
            # No known path/identity yet — the peer must announce first.
            RNS.Transport.request_path(dest_hash)
            _broadcast({"type": "error", "detail": "no path yet; requested (peer must announce)"})
            return
        dest = RNS.Destination(
            recipient, RNS.Destination.OUT, RNS.Destination.SINGLE,
            "lxmf", "delivery",
        )
        lxm = LXMF.LXMessage(
            dest, self.local, payload.encode("utf-8"), title=APP_NAME,
            desired_method=LXMF.LXMessage.DIRECT,
        )
        self.router.handle_outbound(lxm)


async def _ws_handler(websocket, bridge):
    _clients.add(websocket)
    try:
        await websocket.send(json.dumps({"type": "identity", "address": bridge.address}))
        async for raw in websocket:
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if msg.get("type") == "send":
                bridge.send(msg.get("to", ""), msg.get("payload", ""))
    finally:
        _clients.discard(websocket)


async def _serve(bridge, host, port):
    global _loop
    _loop = asyncio.get_running_loop()
    async with websockets.serve(lambda ws: _ws_handler(ws, bridge), host, port):
        RNS.log(f"WebSocket API on ws://{host}:{port}")
        await asyncio.Future()  # run forever


def main():
    parser = argparse.ArgumentParser(description="Polybius Reticulum bridge")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--rns-config", default=None,
                        help="RNS config directory (default ~/.reticulum)")
    parser.add_argument("--storage", default=DEFAULT_STORAGE,
                        help="bridge storage/identity directory")
    parser.add_argument("--announce", action="store_true",
                        help="announce this node on start so peers can reach it")
    args = parser.parse_args()

    bridge = Bridge(configdir=args.rns_config, storage=args.storage,
                    announce_on_start=args.announce)
    # Periodic re-announce so peers keep a path (best-effort).
    if args.announce:
        def _reannounce():
            threading.Timer(300, _reannounce).start()
            try:
                bridge.local.announce()
            except Exception:  # noqa: BLE001
                pass
        threading.Timer(300, _reannounce).start()

    try:
        asyncio.run(_serve(bridge, args.host, args.port))
    except KeyboardInterrupt:
        RNS.log("Polybius bridge stopping")


if __name__ == "__main__":
    main()
