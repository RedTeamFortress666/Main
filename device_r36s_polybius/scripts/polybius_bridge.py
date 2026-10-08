#!/usr/bin/env python3
"""Local WebSocket bridge for Polybius mesh transports.

This is a host/Termux reference, not a system daemon. On the R36S image it is
installed at /system/etc/polybius/polybius_bridge.py.

Transports this process is meant to sit in front of:
  * USB CDC ACM / ttyUSB  (ESP32-S3 LoRa module via OTG)
  * TCP to a local Reticulum / rnsd instance
  * optional SOCKS upstream (Orbot 9050) for any IP fallback

Install a native wrapper at /system/bin/polybius_bridge and set
  setprop ro.polybius.bridge 1
to start it from init.polybius.rc.

Default listen port: 17312 (ro.polybius.bridge.port).
"""

from __future__ import annotations

import argparse
import os
import sys


DEFAULT_PORT = int(os.environ.get("POLYBIUS_BRIDGE_PORT", "17312"))
DEFAULT_SERIAL = os.environ.get("POLYBIUS_SERIAL", "/dev/ttyACM0")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--serial", default=DEFAULT_SERIAL)
    parser.add_argument("--socks", default=os.environ.get("ALL_PROXY", ""))
    args = parser.parse_args()

    print(
        "polybius_bridge: placeholder. Listen ws://127.0.0.1:%d  serial=%s  socks=%s"
        % (args.port, args.serial, args.socks or "none"),
        file=sys.stderr,
    )
    print(
        "Drop a real implementation here, or run Reticulum (rnsd) + a WS gateway.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
