# Linking PØLYBĪUS to Reticulum (RNS)

Short answer: the Flutter app **cannot speak Reticulum directly** — Reticulum
(RNS) and its messaging layer LXMF are Python, and there is **no maintained
Dart/Flutter implementation**. You link to it by running an RNS **daemon**
next to the app and talking to that daemon over a local interface. Nothing in
this repo does that yet; below is the realistic architecture and the concrete
options.

## The model

```
[ PØLYBĪUS Flutter app ]  <-- local IPC (TCP/WebSocket/stdio) -->  [ rnsd + LXMF ]  <-- RNS interfaces -->  mesh
        (Dart)                                                        (Python)          (LoRa / TCP / I2P / serial)
```

- The app produces/consumes **emoji ciphertext** (already done). Reticulum is
  just the **transport** that carries that ciphertext between devices.
- A companion **RNS node** (`rnsd`) handles addressing, encryption at the
  transport layer, and interfaces (LoRa radios, TCP, serial, etc.).
- The app and the node exchange messages over a small local bridge.

## Options, most to least practical

1. **Companion RNS node + local socket bridge (recommended).**
   Run `rnsd` (Python `rns` package) on the same device — on the R36 Linux
   handheld, a Raspberry Pi, an ESP32/LoRa board, or a phone via Termux. Write
   a tiny Python bridge that uses **LXMF** to send/receive messages and exposes
   a **localhost WebSocket/TCP** API. The Flutter app connects with
   `web_socket_channel` / `dart:io` sockets and sends the emoji ciphertext as
   the LXMF payload. This keeps all Reticulum crypto/addressing in the
   supported Python stack and needs only a thin Dart client.

2. **`rnsh` / pipe interface.** For a quick bring-up, pipe ciphertext to an
   `rnsd` instance via a named pipe or `rnsh` command; the app shells out to it
   (native platforms only — not web).

3. **TCP interface to a shared RNS instance.** Point a local bridge at a shared
   `TCPClientInterface`/`TCPServerInterface` so multiple devices join the same
   Reticulum network without direct radio hardware.

## What would need to be built

- A **Python bridge** (`rns` + `lxmf`) exposing a localhost WS/TCP API:
  `send(destination_hash, payload)` and a receive stream. (~100–150 lines.)
- A Dart `ReticulumClient` in the app that connects to that API and pushes/pulls
  the emoji ciphertext. (Thin.)
- Destination/identity management: the RNS **Identity** and destination hashes
  live in the bridge; the app references peers by destination hash (which can
  ride in the existing pool-sync/QR flow).

## Honest limits

- No pure-Dart RNS means the mesh transport must run in the Python node; the
  app is a client of it, not a Reticulum node itself.
- On iOS, running a background Python daemon is not viable — iOS would need a
  remote/companion RNS node reached over TCP.
- Nothing here is wired yet; this document is the plan. Say the word and the
  Python bridge + Dart `ReticulumClient` can be scaffolded as a separate module.
