#!/usr/bin/env python3
"""Two-node local round-trip test for the Polybius Reticulum bridge.

Assumes two bridge instances are already running:
  A on ws://127.0.0.1:8765  (RNS TCPServer)
  B on ws://127.0.0.1:8766  (RNS TCPClient -> A)

Connects to both, reads their addresses, then relays a ciphertext payload from
A to B and verifies B receives it. Retries the send while paths settle.
"""
import asyncio
import json
import sys

import websockets

A_URL = "ws://127.0.0.1:8765"
B_URL = "ws://127.0.0.1:8766"
PAYLOAD = "\U0001F600\U0001F601\U0001F602 POLYBIUS-MESH-TEST"


async def read_identity(ws):
    for _ in range(10):
        raw = await asyncio.wait_for(ws.recv(), timeout=10)
        msg = json.loads(raw)
        if msg.get("type") == "identity":
            return msg["address"]
    raise RuntimeError("no identity frame")


async def main():
    async with websockets.connect(A_URL) as a, websockets.connect(B_URL) as b:
        addr_a = await read_identity(a)
        addr_b = await read_identity(b)
        print(f"A address: {addr_a}")
        print(f"B address: {addr_b}")

        # Let announces propagate across the TCP link.
        print("Waiting for announces to propagate...")
        await asyncio.sleep(12)

        received = asyncio.get_event_loop().create_future()

        async def watch_b():
            while not received.done():
                try:
                    raw = await asyncio.wait_for(b.recv(), timeout=5)
                except asyncio.TimeoutError:
                    continue
                msg = json.loads(raw)
                if msg.get("type") == "message" and not received.done():
                    received.set_result(msg)
                elif msg.get("type") == "error":
                    print(f"B error: {msg.get('detail')}")

        watcher = asyncio.create_task(watch_b())

        # Send from A -> B, retrying while the path settles.
        for attempt in range(1, 9):
            print(f"send attempt {attempt}: A -> B")
            await a.send(json.dumps({"type": "send", "to": addr_b, "payload": PAYLOAD}))
            # Drain any A-side errors (e.g. "no path yet; requested").
            try:
                araw = await asyncio.wait_for(a.recv(), timeout=1)
                amsg = json.loads(araw)
                if amsg.get("type") == "error":
                    print(f"A error: {amsg.get('detail')}")
            except asyncio.TimeoutError:
                pass
            try:
                msg = await asyncio.wait_for(asyncio.shield(received), timeout=6)
                watcher.cancel()
                ok = msg.get("payload") == PAYLOAD
                print(f"B received from {msg.get('from')}: {msg.get('payload')}")
                print("RESULT: PASS" if ok else "RESULT: FAIL (payload mismatch)")
                return 0 if ok else 1
            except asyncio.TimeoutError:
                continue

        watcher.cancel()
        print("RESULT: FAIL (no delivery within timeout)")
        return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
