# PØLYBÎŪS — Developer / Admin Operator Manual

**Classification:** DEV / ADMIN ONLY — do not distribute to everyday V.1 users.  
**Scope:** PORTAL (`hq`), V.1 (`user`), DARTH CHERRY, DOØMSDAY CLØCK, mesh / hardware roadmap.  
**Branch reference:** `cursor/pool-pin-bt-ui-d8fa` (update links when cutting a new release).

---

## 1. What this system is

PØLYBÎŪS is a **covert encrypted messaging stack disguised as a janky 1980s neon arcade shooter**. The public face is the game; the real tool is a multi-rotor emoji cipher reached only through ritual paths and operator login.

| Artifact | Role |
| --- | --- |
| **PØLYBÎŪS PORTAL** | Dev/admin fork — login gate, POOL vault, HQ tools, full ritual → cipher |
| **PØLYBÎŪS V.1** | Everyday user fork — splash → game; cipher via Japanese GAME OVER ritual |
| **DARTH CHERRY** | Night red-light overlay; unlocks stealth typing / secret reveals via local beacon |
| **DOØMSDAY CLØCK** | Privileged chronometer + personal vault + GRØK-REBEL local AI hook |

There is **no mandatory cloud backend**. Crypto, pools, and accounts live on-device. Optional relays (Reticulum bridge, Bluetooth, future LoRa) carry **opaque emoji ciphertext only**.

---

## 2. Safety protocol (operators)

1. **Never** screenshot PORTAL credentials, PIN cards, or POOL grids into shared albums / chat.
2. Install **DARTH CHERRY** before revealing secrets on a shared screen; enable **Display over other apps**.
3. Prefer airplane mode + local BLE / QR when threat model includes network observation.
4. Treat every sideloaded APK as a trust boundary — verify hashes when available; prefer signed release cuts.
5. **Do not** store plaintext of operational messages in Notes / cloud sync. Encrypt first.
6. If a device is seized: revoke that operator’s invite codes, rotate pool seed via QR sync from a clean device, strike the account if compromised.
7. PORTAL devices are higher value — full-disk encryption, lock screen, no USB debugging left on in the field.
8. DOØMSDAY vault unlock phrase is sensitive — do not paste it into cloud notepads.

### Incident severity (quick)

| Level | Example | Action |
| --- | --- | --- |
| L1 | Lost phone, locked | Remote strike account if possible; rotate invites |
| L2 | APK reverse-engineered | Assume ritual paths known; change vault phrase policy / cut new build |
| L3 | Rogue admin | See §8 |
| L4 | Active network attack on bridge | Kill bridge process; fall back to QR / BLE |

---

## 3. User information handling

| Data | Where stored | Notes |
| --- | --- | --- |
| Username / password / PIN | On-device encrypted Hive + secure storage | Never uploaded by default |
| Game file / invite codes | Local settings | Bound per install |
| Daily emoji pool | Local; shareable via QR (PoolSync) | Treat as key material |
| High scores | Local; optional QR merge | Names are operator-chosen — warn against real legal names if OPSEC requires |
| Bluetooth messages | Local session buffers | Ciphertext preferred; decrypt only under veil |
| Reticulum payloads | Opaque emoji over companion bridge | Bridge must not log plaintext |
| DOØMSDAY vault notes | Local SharedPreferences | Unlock is calendar ritual — not a password manager |

**Principle:** collect nothing centrally. If you later add a server for pool/app updates (§7), store **only** signed blobs + device/operator public identifiers — never plaintext messages or PINs.

---

## 4. Flavors, rituals, and what buttons do

### 4.1 PORTAL (`POLYBIUS_FLAVOR=hq`)

**App label:** PØLYBÎŪS PORTAL  

**Boot:** Splash → Layer-1 login → arcade menu.

**Cipher ritual:**

1. SETTINGS → difficulty **11** (blank cell)
2. LANGUAGES → **Russian** → hold SELECT (sets language only)
3. Play → **lose** → hold **GAME OVER** ~6s → ERROR screen
4. Describe incident in **≥6 words** → hold **SAVE AS DRAFT** → **SEND**
5. Diagnostic / invite box under the incident field is **decorative — not required**
6. Log into **DEV ACCESS PORTAL** with operator creds + access code (`B1/D1/W1` / `Tr1` / signed token)

**Cipher tabs:** ENCRYPT · DECRYPT · POOL · SYNC · CONNECT (+ rotor gear)

### 4.2 V.1 (`POLYBIUS_FLAVOR=user`)

**App label:** PØLYBÎŪS V.1  

**Boot:** Splash → game (no Layer-1 login).

**Cipher ritual:** LOAD GAME (file number) → difficulty **11** → **Japanese** → lose → GAME OVER ritual → **USER ACCESS PORTAL**.

**Cipher tabs:** ENCRYPT · DECRYPT · SYNC · CONNECT (no POOL)

### 4.3 Arcade / shell controls

| Control | Does |
| --- | --- |
| START GAME | Flame shooter |
| LOAD GAME | Bind invite / game file; primes V.1 pathway |
| HIGH SCORE | Named scores; QR merge via SYNC |
| SETTINGS | Controls / languages / difficulty / credits |
| ENCRYPT | Plaintext → emoji ciphertext via current rotors + pool |
| DECRYPT | Emoji → plaintext via current rotors + pool |
| POOL (PORTAL) | View 560-emoji map after game file + 6-digit PIN |
| SYNC | QR export/import pool + high scores |
| CONNECT | Bluetooth messaging, identity cards, Reticulum relay |
| Rotor gear | Live rotor positions; decrypt-via-current-rotor |

### 4.4 DARTH CHERRY × cipher

| Gesture | Effect |
| --- | --- |
| Filter ON | Eyeball appears on ENCRYPT / DECRYPT |
| Tap eye | Echo — letters flash then fade |
| Hold eye ~3s | Matrix veil — plaintext hidden (encrypt still works) |
| Filter OFF | Veil drops; **decrypted plaintext is cleared** (also on app resume if filter is off) |

Beacon: `http://127.0.0.1:18766/veil` · matrix signal POST `/mode`.

### 4.5 DOØMSDAY CLØCK

| Area | Behavior |
| --- | --- |
| Login | Privileged operator username / password / PIN |
| Planner vault | Calendar → **5 November** → Gunpowder Plot riddle in note → hold **SAVE NOTE** 3s → OPEN |
| PORTAL slot | Concealable eye toggle for privacy |
| Alarm eye | Visible when DARTH CHERRY installed and/or filter beacon live; **hold 3s with FILTER enabled** → GRØK-REBEL |

---

## 5. Scaling as user numbers grow

1. **Stop hand-issuing invites** — batch-sign tokens (`tool/polybius_sign.dart`) with expiry + tier claims.
2. **Tier the fleet:** PORTAL devices (few) vs V.1 (many). Never give PORTAL builds to casual users.
3. **Pool rotation cadence:** weekly or per-op QR sync; document who is “pool authority” that week.
4. **Observability without surveillance:** optional anonymous crash/version ping over Reticulum (counts only) — never message content.
5. **Support channel:** Proton Mail / LXMF for human support; do not accept ciphertext decrypt requests over email.
6. **Rate-limit bridge relays** on the companion host to blunt spam / DoS.
7. **Split signing keys:** online “update” key vs offline “invite” key; store offline key in a vault (DOØMSDAY / hardware).

---

## 6. Integrating a server for pool updates & app downloads

Goal: push **signed pool seeds** and **APK/IPA update manifests** without building a chat backend.

### 6.1 Recommended architecture

```
[Update authority laptop]
    │  signs manifest (RSA / age / minisign)
    ├─► Proton Drive / Mail (human pull)
    ├─► Static HTTPS mirror (optional)
    └─► Reticulum announce (LXMF / custom destination)
              │
              ▼
     [Operator devices] verify signature → apply pool / prompt update
```

### 6.2 Manifest sketch

```json
{
  "version": 3,
  "issued_at": "2026-08-10T00:00:00Z",
  "pool_seed": "2026-08-10",
  "apk": {
    "portal": "https://…/polybius-v1-stable-hq-android-arm64.apk",
    "user": "https://…/polybius-v1-stable-user-android-arm64.apk",
    "sha256": { "portal": "…", "user": "…" }
  },
  "sig": "…"
}
```

### 6.3 Transport options

| Channel | Pros | Cons |
| --- | --- | --- |
| **Reticulum / LXMF** | Offline-friendly, mesh-native | Needs bridge node; slower |
| **Proton Mail** | Familiar, E2E to humans | Manual; not for high churn |
| **Proton Drive / static HTTPS** | Easy APK hosting | Account / CDN footprint |
| **Bluetooth / QR** | Air-gap | Doesn’t scale past room size |
| **LoRa later** | Long range low bandwidth | Tiny payloads — manifests only |

### 6.4 Client behavior (future work)

- CONNECT → “UPDATE CHECK” polls last-known Reticulum destination or pasted manifest.
- Verify signature against pinned update pubkey shipped in the app.
- Apply pool seed only after confirm; never auto-run unsigned APKs.

---

## 7. Rogue developer / admin response

1. **Immediate:** strike their account in the next roster cut; rotate invite codes they issued.
2. **Keys:** if they had access to signing keys, **retire the keypair** and re-sign all outstanding invites / update manifests.
3. **Builds:** publish a new PORTAL/V.1 cut; notify operators via out-of-band (Proton / in-person).
4. **Forensics:** pull audit logs from a clean device they used (local Hive audit) — assume hostile device is poisoned.
5. **Vault:** treat DOØMSDAY vault contents on their device as burned; regenerate PORTAL APK URLs if needed.
6. **Comms:** announce a “ritual epoch” change (e.g. new difficulty/language pair) only if compromise includes client source — costly; prefer key/account rotation first.
7. **Legal / abuse:** document chain of custody; do not engage the rogue on operational channels.

---

## 8. Handling cyberattacks

| Attack | Mitigation |
| --- | --- |
| APK trojaning | Publish hashes; prefer reproducible builds; sideload only from known raw GitHub / signed mail |
| MITM on update HTTPS | Pin hashes in signed manifest; prefer Reticulum + signature |
| Beacon spoof (`:18766`) | Localhost only; ignore non-loopback; treat veil as UX not crypto |
| BLE sniffing | Assume ciphertext visible; never send plaintext over BT |
| Bridge compromise | Bridge must never see plaintext; rotate RNS identities |
| Brute PIN | Existing 6-digit + device lock; consider attempt backoff in a future cut |
| Social engineering | Support never asks for PIN / backup password |

Remember: **client-side copy protection is not cryptography**. Real security is signed invites, pool secrecy, and OPSEC.

---

## 9. Future LoRa / mesh integration

### Near term

- Keep Reticulum companion (`polybius_bridge.py`) as the mesh gateway for phones.
- BLE for room-scale operator chat (already in CONNECT).
- QR for air-gapped pool sync.

### Medium term

- **LoRaWAN / raw LoRa** on LilyGO T-Deck / T-Beam as Reticulum interfaces (`RNode` / Reticulum LoRa).
- Fragment emoji ciphertext into LoRa frames; reassembly on peer.
- DOØMSDAY or PORTAL “mesh health” panel: last heard, SNR, battery.

### Design rules

- Phones stay UX terminals; ESP32 / T-Deck are radio mules.
- No plaintext on RF. No automatic contact sync to cloud.
- Prefer store-and-forward over always-on links.

---

## 10. Porting plan — R36S, LilyGO T-Deck, ESP32 CYD

### 10.1 R36S (ArkOS / ROCKNIX / JELOS)

| Path | Status / plan |
| --- | --- |
| Linux aarch64 bundle / Port zip | Exists under `dist/` — launch via Ports menu |
| OTA | Not true OTA — push new Port zip via SD or SCP |
| From Android | USB/MTP or local HTTP (`python -m http.server`) → copy to TF card `ports/` |
| Limits | Mali/GTK GL quirks; gamepad via `gptokeyb`; cipher OK if Flutter builds |

**Steps:** build `linux-arm64` → package Port → operators overwrite `ports/polybius/` → reboot Ports.

### 10.2 LilyGO T-Deck

| Path | Plan |
| --- | --- |
| Firmware | PlatformIO under `polybius/firmware/` |
| Transfer | USB serial flash; SD asset drop for fonts/pools; later BLE OTA from phone |
| Role | Keyboard handheld: compose → encrypt on-device or act as Reticulum LoRa node |
| BLE | Pair to Android PORTAL for tethered ciphertext relay |

### 10.3 ESP32 CYD (Cheap Yellow Display)

| Path | Plan |
| --- | --- |
| Firmware | Same PlatformIO family; smaller UI (ciphertext viewer / QR) |
| Transfer | USB; SD; **BLE tether** from Android (push signed pool seed + message queue) |
| OTA | ESP32 Arduino/PIO OTA on LAN once; field prefer SD + BLE |

### 10.4 Unified field update flow (target)

```
Android PORTAL  --BLE/USB-->  T-Deck / CYD  (firmware chunk + pool seed)
Android PORTAL  --HTTP/SD-->  R36S Port zip
Authority       --RNS/Proton-->  Android update manifest
```

Priority order for implementation:

1. Signed update manifest + manual apply on Android  
2. BLE “push pool seed” to ESP32 firmware  
3. LoRa RNode under Reticulum  
4. One-tap “mirror APK to SD for R36S” helper in CONNECT  

---

## 11. Download index (operators)

Replace branch segment if you cut a new release branch.

- PORTAL APK: `polybius/dist/polybius-v1-stable-hq-android-arm64.apk`
- V.1 APK: `polybius/dist/polybius-v1-stable-user-android-arm64.apk`
- V.1 iOS (Safari web portable): `polybius/dist/polybius-v1-stable-user-ios-web-portable.zip`
- DARTH CHERRY: `polybius/dist/darth-cherry-1.0.2-android-arm64.apk`
- DOØMSDAY BUNKER v1: `polybius/dist/doomsday_clock/doomsday-bunker-v1-android-arm64.apk`
- DOØMSDAY CLØCK (stable): `polybius/dist/doomsday_clock/doomsday-clock-stable-android-arm64.apk`

Details: `docs/V1_STABLE.md`, `docs/OPERATOR_ACCOUNTS.md`, `docs/RED_VEIL.md`, `docs/RETICULUM.md`, `docs/ESP32.md`.

---

## 12. Maintainer checklist (each release)

- [ ] `flutter test` in `polybius/` and `doomsday_clock/`
- [ ] Build HQ + user arm64 APKs; force-add to `dist/`
- [ ] Rebuild Doomsday if vault / veil changed
- [ ] Confirm Darth Cherry package id still `com.polybius.red_veil` and beacon `:18766`
- [ ] Update this manual’s download paths / ritual notes
- [ ] Notify admins on Proton / LXMF with hashes

*— end of DEV manual —*
