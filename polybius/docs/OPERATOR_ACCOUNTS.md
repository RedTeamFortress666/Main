# PØLYBĪUS — operator accounts (V1 Stable)

Credentials bootstrapped on first install. Source of truth:

- Named operators: `lib/core/constants/app_constants.dart`
- BETA pool (10): `lib/core/constants/operator_roster.dart`
- In-app cards: CONNECT → identity card button
  - **Full roster** only for DEV accounts: SpamKat2 / RedTeam01 / Gam3.0n
  - Every other account sees **only their own** card
  - Public: neon Illuminati / matrix eye + username + invite / game-file code
  - Under **DARTH CHERRY**: password, backup password, PIN

~~**DEVELOPER / `developer`**~~ — **STRICKEN** for V1 Stable. Login is rejected
and the bootstrap account is purged on upgrade.

## Downloads (V1 Stable)

Branch: `cursor/pool-pin-bt-ui-d8fa`

| Build | Link |
| --- | --- |
| **PØLYBÎŪS PORTAL** (Dev Admin / triple tier) | [polybius-v1-stable-hq-android-arm64.apk](https://github.com/RedTeamFortress666/Main/raw/cursor/pool-pin-bt-ui-d8fa/polybius/dist/polybius-v1-stable-hq-android-arm64.apk) |
| **PØLYBÎŪS V.1** (ENCRYPT / DECRYPT / SYNC / CONNECT) | [polybius-v1-stable-user-android-arm64.apk](https://github.com/RedTeamFortress666/Main/raw/cursor/pool-pin-bt-ui-d8fa/polybius/dist/polybius-v1-stable-user-android-arm64.apk) |
| DARTH CHERRY dimmer | [darth-cherry-1.0.2-android-arm64.apk](https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/darth-cherry-1.0.2-android-arm64.apk) |

See also `docs/V1_STABLE.md`.

Use invite / access codes at **LOAD GAME** / portal. Login with username + password; PIN for re-auth. Backup password is an alternate login password.

---

## Built-in / named operators

| Display | Username | Tier | Invite / access code | PIN | Password | Backup password |
|---------|----------|------|----------------------|-----|----------|-----------------|
| ~~DEVELOPER~~ | ~~`DEVELOPER`~~ | — | — | — | ~~`developer`~~ | **STRICKEN** |
| RedTeam01 | `REDTEAM01` | admin | `B1-66-3R` | `816639` | `816639` | `816639` |
| SpamKat2 | `SPAMKAT2` | developer | `W1-66-3R` | `810739` | `Ev1l-Schm33` | `LilB1tScary99` |
| Gam3.0n | `GAM3.0N` | developer | `B1-66-3R` | `816639` | `Dig1tal.Ra1n99` | `01-p0lyb1u5-10` |
| KASP3R | `KASP3R` | admin | `TR1-66-3R` | `791639` | `BurnHideFr13d` | `P1ckl3M0rty69` |
| T3mptress | `T3MPTRESS` | agent (standard invite) | `80-081-35` | `808135` | `not1nkansas69` | `NoPlaceL1ke` |
| CrownOfCorns | `CROWNOFCORNS` | admin | `C0-9N-3E` | `539667` | `20YokoMicrowave14` | `C0rnS1lo14` |
| MizzPickl3s | `MIZZPICKL3S` | agent (standard invite) | `SP-1N-33` | `080826` | `8-Bit.Bitch3s` | `Glitch.B1tch99` |
| P!k.ZuP | `P!K.ZUP` | admin | `D4-N6-3R` | `839093` | `DocCh1ck3n` | `TakeAOrdaPr33z` |

---

## Pool (10 Admin/user roster)

| Display | Username | Tier | Invite code | PIN | Password | Backup password |
|---------|----------|------|-------------|-----|----------|-----------------|
| NiteQueen | `NITEQUEEN` | admin | `NQ1-66-3R` | `314159` | `NiteOwl42` | `NightOwl7` |
| Art3mas | `ARTEM3S` | admin | `AR2-66-3R` | `271828` | `BowArrow7` | `Huntress9` |
| Cup1d! | `CUP1D!` | agent | `CU3-66-3R` | `161803` | `LoveShot99` | `CupidsBow1` |
| Dyslex1c | `DYSLEX1C` | agent | `DX4-66-3R` | `141421` | `SpellMix8` | `LexiFix99` |
| WhyTwoK | `WHYTWOK` | agent | `Y2K-66-3R` | `173205` | `PartyY2K1` | `TwoKWave2` |
| M00nFox | `M00NFOX` | agent | `MF5-66-3R` | `223606` | `MoonRun88` | `FoxMoon11` |
| V3ctorKid | `V3CTORKID` | agent | `VK6-66-3R` | `244949` | `VecTor99` | `KidVector3` |
| Gl1tchCat | `GL1TCHCAT` | agent | `GC7-66-3R` | `264575` | `CatGlitch1` | `GlitchMe2` |
| H0neyBad | `H0NEYBAD` | agent | `HB8-66-3R` | `331127` | `HoneyRun7` | `BadHoney9` |
| PixelW1z | `PIXELW1Z` | agent | `PW9-66-3R` | `367879` | `PixelZap12` | `WizPixel5` |
