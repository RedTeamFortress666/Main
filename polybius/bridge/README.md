# PØLYBĪUS Reticulum bridge

A companion node that carries the app's emoji ciphertext over a
[Reticulum](https://reticulum.network/) mesh (LXMF), exposing a localhost
WebSocket the Flutter app connects to. There is no Dart RNS implementation, so
Reticulum runs here in Python and the app is a thin client of it.

## Run

```bash
cd polybius/bridge
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Start it (announce so peers can find you):
python3 polybius_bridge.py --announce
# -> prints your address (hex destination hash) and serves ws://127.0.0.1:8765
```

Configure Reticulum interfaces (LoRa / TCP / serial / I2P) in
`~/.reticulum/config` as usual — the bridge uses whatever RNS is configured to
use. For two machines with no radios, add a `TCPClientInterface` /
`TCPServerInterface` so they share a network.

## Use from the app

1. Start this bridge on the same device (or a companion device reachable at the
   WebSocket URL).
2. In the app: cipher **CONNECT** tab → **RETICULUM RELAY** → it connects to
   `ws://127.0.0.1:8765` and shows your address.
3. Share your address with a peer (paste it, or ride it alongside the SYNC QR).
4. Encrypt on the ENCRYPT tab, then relay the ciphertext to a peer's address;
   inbound ciphertext appears in the relay screen to copy into DECRYPT.

## Protocol (JSON over WebSocket)

| Direction | Frame |
|-----------|-------|
| server→client (on connect) | `{"type":"identity","address":"<hex>"}` |
| client→server (transmit)   | `{"type":"send","to":"<hex>","payload":"<ciphertext>"}` |
| server→client (receive)    | `{"type":"message","from":"<hex>","payload":"<ciphertext>"}` |
| server→client (problem)    | `{"type":"error","detail":"..."}` |

`payload` is opaque; the bridge never sees plaintext or the cipher mapping.

## Scaffold status / to harden

- **Path discovery**: sending needs a known path to the recipient (the peer must
  have announced and this node recalled its identity). The bridge requests a
  path if missing but does not queue/retry — add retry + delivery receipts.
- **iOS**: can't run a background Python daemon; point the app at a companion
  device's bridge over TCP instead.
- **Auth**: the WebSocket is unauthenticated localhost. If you expose it beyond
  loopback, add a token.
