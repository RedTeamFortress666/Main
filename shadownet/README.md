# Shadøwnet × QShield

Android-focused developer mesh console for binding **Abliterated** uncensored local LLM weights (2–6 GB GGUF) to inference **connect points**, with **QShield** hybrid post-quantum transport sealing.

Authorized security research / developer lab use.

## Features

| Layer | Capability |
| --- | --- |
| **Shadøwnet Mesh** | Manage connect points for llama.cpp, KoboldCpp, MLC LLM, Ollama, custom HTTP |
| **Model Vault** | Catalog of Abliterated 2–6 GB presets; bind/scan local `.gguf` files |
| **QShield Core** | X25519 + Kyber512-framed hybrid session; AES-GCM payload sealing |
| **Inference Bridge** | OpenAI-compatible `/v1/chat/completions` calls through connect points |

## Prerequisites

- Flutter 3.44.x (Dart 3.12+)
- Android SDK; device or emulator for on-device testing

```bash
cd shadownet
flutter pub get
flutter analyze
flutter test
```

## Run on Android

```bash
flutter run -d android
```

## Local model workflow

1. Download an Abliterated GGUF (2–6 GB) to the phone (e.g. `Download/models/`).
2. Open **MODELS** → **SCAN FOLDER** or **BIND GGUF FILE**.
3. Open **CONNECT** → configure llama.cpp server URL (default `http://127.0.0.1:8080`).
4. **PROBE** the endpoint; **LINK MODEL** to the downloaded weight.
5. Open **QSHIELD** → **ESTABLISH SESSION**.
6. **BRIDGE** tab → send a prompt with QShield sealing enabled.

### Example llama.cpp server on device (Termux / side-loaded)

```bash
./llama-server -m /path/to/model.gguf --host 127.0.0.1 --port 8080
```

## Connect point defaults

| Label | URL | Backend |
| --- | --- | --- |
| Llama.cpp Server | `http://127.0.0.1:8080` | OpenAI API |
| KoboldCpp Bridge | `http://127.0.0.1:5001` | Kobold |
| MLC LLM Local | `http://127.0.0.1:8000` | MLC |

## QShield transport

Hybrid profile: `X25519+Kyber512`. Inference payloads may be wrapped as:

```json
{
  "qshield_sealed": "<base64 AES-GCM>",
  "hybrid": "X25519+Kyber512",
  "key_id": "<pqc key id>"
}
```

Header: `X-QShield-Session`. Kyber512 key_id framing aligns with Phant0m field protocol (`phant0m/` on branch `cursor/phant0m-f1rmwar3-cyd-640a`).

## Build release APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
