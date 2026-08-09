# Android setup — PØLYBĪUS + DARTH CHERRY + Reticulum

Operator pack for **admin / Android**. Use with the Admin APK and DARTH CHERRY dimmer.

## 1. Install Polybius (Android)

1. Enable **Install unknown apps** for your browser / Files.
2. Download the Admin APK (scan the operator QR or use the raw GitHub link).
3. Install → open **PØLYBĪUS**.
4. Ritual unlock: hold title **6s** → SETTINGS → difficulty **11** → LANGUAGES → **Russian** → hold SELECT **3s**.
5. Portal: username · password (or backup) · invite / game file → then **6-digit PIN**.

## 2. Install DARTH CHERRY (screen dimmer)

1. Download [darth-cherry-1.0.2-android-arm64.apk](https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/darth-cherry-1.0.2-android-arm64.apk).
2. Open DARTH CHERRY → grant **Display over other apps** → **ENABLE FILTER**.
3. Return to Polybius cipher ENCRYPT/DECRYPT:
   - Tap eyeball = fade-type
   - Hold through 3s red-pupil blink = matrix green veil (plaintext hidden)

## 3. Link Reticulum (mesh transport)

Polybius does **not** speak Reticulum natively. It talks to a local Python **RNS + LXMF bridge** over WebSocket; the bridge carries emoji ciphertext on the mesh.

```
[ PØLYBĪUS Android ]  --ws://host:8765-->  [ polybius_bridge.py + rnsd ]  --RNS-->  mesh
```

### On a companion host (recommended)

Phone (Termux), Pi, or R36 Linux next to the handset:

```bash
pip install rns lxmf websockets
# From the Polybius repo (or copy bridge onto the host):
python polybius/tools/polybius_bridge.py   # default ws://0.0.0.0:8765
```

Bring up Reticulum interfaces (`~/.reticulum/config`) for TCP / LoRa / serial as needed. See [RETICULUM.md](../../docs/RETICULUM.md).

### In the Polybius app

1. After cipher unlock, open the **Reticulum relay** screen.
2. Set bridge URL (USB/emulator: `ws://127.0.0.1:8765`; LAN companion: `ws://<host-ip>:8765`).
3. Connect → send / receive emoji ciphertext as LXMF payloads.

### Android notes

- Android alone cannot run a full background RNS daemon as cleanly as Termux or a Pi — use a **companion node** on the same Wi‑Fi, or Termux with wake locks.
- iOS cannot host the daemon; use a remote companion over TCP.
- Bridge must be reachable; firewall / AP isolation will block LAN WS.

## 4. Verify

| Check | Expect |
| --- | --- |
| Portal login | Admin tier opens full engine |
| DARTH CHERRY overlay | Red filter + eyeball on cipher screen |
| Bridge connect | Identity frame / no error in relay UI |
| Send test | Peer receives emoji ciphertext over LXMF |

## Links

- Polybius docs: `polybius/docs/RETICULUM.md`
- Bridge / client: `polybius/lib/features/reticulum/`
- Operator cards: `polybius/dist/operators/`
