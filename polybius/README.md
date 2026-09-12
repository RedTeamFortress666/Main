# PØLYBĪUS

Cross-platform covert encrypted messaging disguised as a janky retro 1980s psychedelic neon arcade space shooter.

## Platforms

- Android, iOS, GrapheneOS
- Windows, macOS, Linux desktop
- Web export (for emulation devices / SD-card Linux handhelds like R36S Ultra)

## Quick Start

```bash
cd polybius
flutter pub get
flutter run          # mobile/desktop
flutter run -d chrome # web
```

**First login:** `DEVELOPER` / `developer` (bootstrapped on first install)

## Architecture

Five cabinets, one arcade. They do not share state except through the
providers in `lib/core/providers/app_providers.dart`.

```
lib/
├── core/                # constants, AES-at-rest, HKDF, hybrid envelope
├── features/
│   ├── auth/            # login gate + PIN (real or cover)
│   ├── arcade/          # decoy menu, high scores, settings
│   ├── cipher/          # rotors, pool manager, QR sync
│   ├── redlight/        # vanishing field + dual-layer keyboard
│   ├── duress/          # cover identity (in-memory session)
│   ├── transport/       # QR + Reticulum sidecar + Matrix fallback
│   └── game/            # Flame shooter
├── app.dart
└── main.dart
```

| Layer | Owns | Must not own |
|---|---|---|
| Arcade shell | CRT, scores, lamp chrome | Seeds, PINs, frames |
| Cipher engine | Rotors, 2/3-glyph map, stego decoys | UI, network |
| Pool manager | 24h draw, 2h remap | Transport |
| Redlight | Derangement, vanishing buffer | Ciphertext |
| Transport | Padded frames, RNS/Matrix/QR | Plaintext |

Honest limits: AES-256-GCM is the payload cipher (there is no AES-512).
X25519 is live. ML-KEM is a format slot, not an audited Kyber. Reticulum
is a loopback sidecar, not an embedded Python stack. Cover PIN sessions
look identical in the arcade; a Hive dump still shows that a cover record
exists. The leak detector names that residual. The auto-patcher weaves
cabinet policy (V2 ticket, phosphor mixer, real-seed chrome, V1 without
decoys, dual-density decrypt, cover PIN gate, tofu filter). It does **not**
patch the binary or hide a Hive dump.

## Three Layers

### Layer 1 — Login Gate (V2 protocol)

OPERATOR ID + ACCESS KEY. The CRT then runs six steps:

| Step | Name | What actually happens |
|---|---|---|
| 01 | CHALLENGE | Random nonce for this handshake |
| 02 | VERIFY | PBKDF2 on the access key. Same `ACCESS DENIED` for unknown operator or bad key |
| 03 | TICKET | Device-bound session `v2:USER:issued:nonce:mac` |
| 04 | LEAK SWEEP | Patcher DETECT phase — the CRT prints the real count, e.g. `7 OPEN` |
| 05 | AUTOPATCH | APPLY → VERIFY → LEDGER — e.g. `7 WOVEN #1` (or `n PENDING` if something could not close) |
| 06 | CABINET | Ready, or PIN gate |

The ticket is HMAC’d with the working AES key. Swapping the operator name in the session box fails the MAC. It is **not** a password proof after the fact. A ticket older than **14 days** is dropped on restore (`TICKET_EXPIRED` audit) and the operator logs in again; a rolled-back clock counts as expired. First install still creates `DEVELOPER`.

### Interwoven auto-patcher

One pipeline, five triggers, one ledger.

```
DETECT  LeakDetector.scan(snapshot)          → N OPEN
APPLY   7 PatchSteps fold CabinetPolicy      + 2 storage hooks (ticket, mixer)
VERIFY  LeakDetector.scan(snapshot')         → M OPEN
LEDGER  PatchLedgerEntry{seq, trigger, N→M, per-step outcome, policy}
        mac = HMAC(device key, prevMac | canonical)
```

| Trigger | When |
|---|---|
| `LOGIN` | Handshake steps 04/05 |
| `RESTORE` | App start with a valid ticket (verifies the ledger chain before any cipher tab renders) |
| `CHERRY` | Darth Cherry arms (LOAD GAME code or Developer toggle) |
| `SYNC` | A pool token is imported on the SYNC tab |
| `MANUAL` | Developer panel → RUN WEAVE |

The first weave on a device is tagged `BASELINE·<trigger>` and detects against the compiled legacy policy, so the ledger's first line records what the cabinet would have leaked out of the box. Later weaves detect against the live policy and mostly read `HELD`.

Per-step outcomes: `APPLIED` (open→patched), `HELD` (already patched), `PENDING` (still open — e.g. no session to bind a ticket to), `RESIDUAL` (named, not remediable in-app). The ledger is MAC-chained under the device key: editing an old entry, deleting a middle one, or copying the settings box to another device breaks the chain, which the detector reports as an OPEN `PATCH LEDGER` finding and audits as `LEDGER_TAMPER`. The ledger is capped at 64 entries; the surviving tail still verifies.

What it is not: a binary updater, a network fetch, or a way to hide the cover record. `SignatureService.verifyPayload` still has no install path (BUILD.md).

### Layer 2 — Decoy Arcade
Psychedelic neon CRT main menu with playable space shooter. MKUltra-themed level names, subliminal glitch text, ship upgrades MK-I → MK-V.

### Layer 3 — Hidden Cipher
Multi-rotor engine. Default **2 glyphs per character** (optional 3). Daily
master draw, remapped every 2 UTC hours. The second glyph is *not* the
plaintext index.

## Unlock Rituals

| Ritual | Steps | Result |
|--------|-------|--------|
| Title hold | Hold **PØLYBĪUS** title 3s | Hint state + fake crash |
| Difficulty 11 | SETTINGS → difficulty 11 + ENGLISH | Partial unlock |
| Compound | SETTINGS → difficulty 7 + RUSSIAN | Full cipher unlock |
| Invite code | LOAD GAME → valid `PB-XXXXXXXX` code | Cipher unlock |
| Dev codes | LOAD GAME → `B1-66-3R` or `D1-66-3R` + CHINESE language | Developer panel |
| Darth Cherry | LOAD GAME → `DARTH-CHERRY` or `CH3-RRY`, or Developer panel toggle | Glyph keyboard + leak detector + auto-patcher |

## Cipher Tabs

- **🔒 ENCRYPT** — advanced V1 plaintext field → emoji ciphertext (2 glyphs/char, no decoys). Glyph keyboard only after **Darth Cherry** is armed. Cherry shows the leak sweep.
- **🔓 DECRYPT** — emoji → plaintext
- **🎲 POOL** — active 560-glyph window + slot
- **🔗 SYNC** — QR / padded courier token
- **📡 CONNECT** — QR / RNS / Matrix status, logout
- **⚙ Rotor Gear** — odometer positions (notch is flavour only). **GEAR CAL** re-opens the PIN gate so a cover PIN can be entered while logged in.

## Build

```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build windows    # Windows
flutter build macos      # macOS
flutter build linux      # Linux
flutter build web        # Web / emulation devices
```

## Tests

```bash
flutter test
```

## Security Notes

- Sensitive account data encrypted at rest (AES via `flutter_secure_storage`)
- Audit logging for all cipher operations and unlock attempts
- Dev shortcuts hidden in release builds (`kDebugMode`)
- Pool forcing logs out all users (including DEVELOPER) and requires PIN re-auth
- V2 session tickets are HMAC-bound to the device key; they are not a password proof, and they age out after 14 days
- The patch ledger is MAC-chained under the device key; a broken chain is an OPEN leak finding, not a silent reset

## Legal

The code cannot stop a device owner from patching their own copy — that is the
`CLIENT OWNED` residual. `LEGAL/` holds the paper remedy: an EULA to ship with
builds, DMCA / DSA takedown and cease-and-desist templates, and a leak-response
runbook (evidence, key rotation, then letters). Templates, not legal advice.

## Brainstorm — next weaves

Ideas that fit the honest-crypto rule. None are implemented; each names the surface it would close and what it would still leave open.

- **Signed policy manifest.** Ship `CabinetPolicy.canonical` + a version inside a `SignedToken` (RSA-4096, offline key, same path as invites). The patcher would refuse a policy that is not signed and newer than the embedded baseline. Closes: a Hive edit flipping a flag between weaves. Leaves open: the device owner can still patch the verifier.
- **Ledger anchor in the courier token.** Put the latest ledger MAC (8 chars) into the SYNC QR so the peer's cabinet records which weave the pool was aligned under. Closes: "which policy was live when this pool was cut" ambiguity. Leaves open: nothing new; it is display-only unless both ends compare.
- **Ticket rotation on sensitive actions.** GEAR CAL, cover-identity arm and pool force each re-issue the ticket (new nonce, new MAC) and chain a weave. Closes: a copied session box staying valid for the full 14 days after a checkpoint. Leaves open: copies made before the rotation are only killed by the age limit.
- **Slot-bound mixer.** Derive the phosphor mixer per 2-hour slot from the stored mixer + slot index, so a shoulder-surfed keyboard layout is stale after the remap. Closes: layout recall across slots. Leaves open: within-slot recall.
- **Pending-outcome nudge.** When a weave ends with `PENDING`, the Cherry banner shows the step title instead of a green bar (e.g. `PENDING · V2 TICKET`). Closes: a false all-clear on the encrypt screen. Leaves open: nothing; UX only.
- **Duress-aware weave.** A weave triggered during a cover session must not write the cover username into the ledger. Today the entry records `operatorUsername` only in the audit actor, never in the ledger — keep it that way, and add a test that greps the ledger JSON for the cover initials.
- **Ledger export as padded frame.** Let the Developer panel export the ledger over the same padded transport frame as ciphertext so an operator can carry a weave history to a second device without a screenshot. Closes: out-of-band review. Leaves open: the export is only as trustworthy as the device key that signed it.
- **Web key honesty.** On web the "device key" is obfuscation, not a keystore (BUILD.md). Add a `platform.key` finding that reads `RESIDUAL` on web and `PATCHED` on native, so the leak strip stops implying parity.
