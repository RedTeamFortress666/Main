# Polybius on iOS — operator manual

This guide covers the **iOS / Safari web-portable** build (and future `.ipa` when CI produces one). Android-only pieces (DARTH CHERRY overlay) are called out.

## 1. Install (Safari web portable)

1. On iPhone / iPad, open the Art3mas (or your operator) **iOS QR** or download link  
   → `polybius-*-web-portable.zip`.
2. Unzip in **Files** (or AirDrop the unzipped folder to the device).
3. Preferred: host the folder on a local static server / GitHub Pages / LAN share, then open `index.html` in **Safari**.  
   Opening `file://` directly can block storage / WASM — serve over **https://** or **http://localhost**.
4. Safari → **Share** → **Add to Home Screen** for an app-like icon (standalone display).
5. Launch from the Home Screen icon.

### Native IPA (when available)

```text
flutter build ios --release --no-codesign
```

Unsigned IPA requires a Mac + Xcode; distribution needs your Apple Developer signing. Until then, use the web portable.

## 2. First boot / intro

Every build now opens with the cinematic boot:

1. **PØLYBĪUS** logo  
2. Matrix rain + neon third eye (green / pink-red / yellow) with `?` pupil blinks  
3. Black beat → typewriter: `brought to you by GÅMÊ ØVĒR...`  
4. CRT power-off to a white dot  
5. `loading...` (~2s)  
6. Start / login screen  

Do not force-quit during the intro; it only runs once per cold start.

## 3. Login (admin example — Art3mas)

| Field | Value |
| --- | --- |
| Login | `Art3mas` |
| Password | `BowArrow7` (or backup `Huntress9`) |
| Invite / game file | `AR2-66-3R` |
| PIN | `271828` |

Portal ritual (cipher engine): hold title **6s** → SETTINGS → difficulty **11** → LANGUAGES → **Russian** → hold SELECT **3s** → enter credentials.

Admin tier unlocks the full crypto engine when the invite is accepted at the portal.

## 4. iOS limits vs Android

| Feature | iOS web / IPA | Android |
| --- | --- | --- |
| Cipher + arcade | Yes | Yes |
| Admin / agent portal | Yes | Yes |
| DARTH CHERRY screen dimmer | **No** (Android overlay only) | Yes |
| Reticulum mesh | Needs **companion** RNS node over LAN WebSocket — iOS cannot host `rnsd` | Termux / companion Pi |

Reticulum setup: see [ANDROID_RETICULUM_SETUP.md](./ANDROID_RETICULUM_SETUP.md) and `polybius/docs/RETICULUM.md`. Point the in-app relay at `ws://<companion-ip>:8765`.

## 5. Storage & privacy

- Web portable uses browser / PWA storage — clearing Safari data wipes local accounts on that device.
- Prefer a dedicated Home Screen PWA profile for operators.
- Do not screenshot credential cards into shared albums.

## 6. Troubleshooting

| Symptom | Fix |
| --- | --- |
| Blank screen after zip open | Serve over http(s), not `file://` |
| Login fails | Username is case-insensitive; use invite `AR2-66-3R` |
| Intro stuck | Wait ~12–15s for the full sequence; reload once |
| No matrix veil | DARTH CHERRY is Android-only |

## Links

- Art3mas card: [art3mas.md](./art3mas.md)  
- Operator index: [README.md](./README.md)  
- Android + Reticulum: [ANDROID_RETICULUM_SETUP.md](./ANDROID_RETICULUM_SETUP.md)
