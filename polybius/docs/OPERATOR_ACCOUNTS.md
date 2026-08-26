# PØLYBĪUS — operator accounts (V1 Stable)

## Downloads

| Build | Accounts at login | APK |
| --- | --- | --- |
| **PØLYBÎŪS PORTAL** (Dev Admin) | All **24** dev/admin operators | [polybius-v1-stable-hq-android-arm64.apk](https://github.com/RedTeamFortress666/Main/raw/cursor/portal-user-login-e16f/polybius/dist/polybius-v1-stable-hq-android-arm64.apk) |
| **PØLYBÎŪS V.1 USER** | All **50** user/agent operators | [polybius-v1-stable-user-android-arm64.apk](https://github.com/RedTeamFortress666/Main/raw/cursor/portal-user-login-e16f/polybius/dist/polybius-v1-stable-user-android-arm64.apk) |

**Login rules:** Portal accepts developer + admin tiers only. V.1 USER accepts agent tier only. Wrong APK shows a redirect hint. Full credential tables below.

Also: [iOS web portable](https://github.com/RedTeamFortress666/Main/raw/cursor/portal-user-login-e16f/polybius/dist/polybius-v1-stable-user-ios-web-portable.zip) · [DARTH CHERRY](https://github.com/RedTeamFortress666/Main/raw/cursor/portal-user-login-e16f/polybius/dist/darth-cherry-1.0.2-android-arm64.apk)

Credentials bootstrapped on first install. Source of truth:

- Named operators: `lib/core/constants/app_constants.dart`
- BETA pool (10): `lib/core/constants/operator_roster.dart`
- Wave 2 (5 admin + 3 developer + 20 user): `lib/core/constants/operator_wave2.dart`
- Wave 3 (5 admin + 3 developer + 20 user): `lib/core/constants/operator_wave3.dart`
- In-app cards: CONNECT → identity card button
  - **Full roster** only for DEV accounts: SpamKat2 / RedTeam01 / Gam3.0n
  - Every other account sees **only their own** card
  - Public: neon Illuminati / matrix eye + username + invite / game-file code
  - Under **DARTH CHERRY**: password, backup password, PIN

**Ritual + full credential checklist for testing:** [`docs/RITUAL_TEST_MATRIX.md`](./RITUAL_TEST_MATRIX.md)

~~**DEVELOPER / `developer`**~~ — **STRICKEN** for V1 Stable. Login is rejected
and the bootstrap account is purged on upgrade.

See also [`docs/V1_STABLE.md`](./V1_STABLE.md).

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

---

## Wave 3 (5 admin + 3 developer + 20 user)

Fresh-install bootstrap. Invite family: admins `*-99-3R`, developers `*-00-3R`, users `U21–U40-44-3R`.

### Admins (PORTAL)

| Display | Username | Invite | PIN | Password | Backup password |
|---------|----------|--------|-----|----------|-----------------|
| V0ltStag | `V0LTSTAG` | `VS1-99-3R` | `701122` | `VoltStag91` | `StagVolt3` |
| Cr1ms0nRx | `CR1MS0NRX` | `CX2-99-3R` | `712233` | `CrimsonRx2` | `RxCrimson8` |
| Obs1dian | `OBS1DIAN` | `OD3-99-3R` | `723344` | `Obsidian77` | `DianObsi5` |
| StormK3l | `STORMK3L` | `SK4-99-3R` | `734455` | `StormKel44` | `KelStorm6` |
| ApexW0lf | `APEXW0LF` | `AW5-99-3R` | `745566` | `ApexWolf9` | `WolfApex1` |

### Developers (PORTAL)

| Display | Username | Invite | PIN | Password | Backup password |
|---------|----------|--------|-----|----------|-----------------|
| B1tF0rge | `B1TF0RGE` | `BF1-00-3R` | `801177` | `BitForge91` | `ForgeBit2` |
| GhostAsm | `GHOSTASM` | `GA2-00-3R` | `812288` | `GhostAsm8` | `AsmGhost4` |
| Zer0Kern | `ZER0KERN` | `ZK3-00-3R` | `823399` | `ZeroKern7` | `KernZero3` |

### Users (V.1 USER)

| Display | Username | Invite | PIN | Password | Backup password |
|---------|----------|--------|-----|----------|-----------------|
| Aur0raFox | `AUR0RAFOX` | `U21-44-3R` | `710101` | `AuroraFx21` | `FoxAurora1` |
| B0real1s | `B0REAL1S` | `U22-44-3R` | `710202` | `Borealis22` | `LisBorea2` |
| C1nderSki | `C1NDERSKI` | `U23-44-3R` | `710303` | `CinderSki3` | `SkiCinder3` |
| DuskRav3n | `DUSKRAV3N` | `U24-44-3R` | `710404` | `DuskRaven4` | `RavenDusk4` |
| EmberLynx | `EMBERLYNX` | `U25-44-3R` | `710505` | `EmberLynx5` | `LynxEmber5` |
| FrostW1sp | `FROSTW1SP` | `U26-44-3R` | `710606` | `FrostWisp6` | `WispFrost6` |
| Gild3dFin | `GILD3DFIN` | `U27-44-3R` | `710707` | `GildedFin7` | `FinGilded7` |
| Hal0Drift | `HAL0DRIFT` | `U28-44-3R` | `710808` | `HaloDrift8` | `DriftHalo8` |
| IrisNova | `IRISNOVA` | `U29-44-3R` | `710909` | `IrisNova29` | `NovaIris9` |
| Jad3Spark | `JAD3SPARK` | `U30-44-3R` | `711010` | `JadeSpark0` | `SparkJade1` |
| K0iWave | `K0IWAVE` | `U31-44-3R` | `711111` | `KoiWave31` | `WaveKoi2` |
| LunarB1t | `LUNARB1T` | `U32-44-3R` | `711212` | `LunarBit32` | `BitLunar3` |
| MystW1re | `MYSTW1RE` | `U33-44-3R` | `711313` | `MystWire33` | `WireMyst4` |
| NyxFlare | `NYXFLARE` | `U34-44-3R` | `711414` | `NyxFlare34` | `FlareNyx5` |
| OpalR1ft | `OPALR1FT` | `U35-44-3R` | `711515` | `OpalRift35` | `RiftOpal6` |
| PulseF0x | `PULSEF0X` | `U36-44-3R` | `711616` | `PulseFox36` | `FoxPulse7` |
| QuasarK1t | `QUASARK1T` | `U37-44-3R` | `711717` | `QuasarKit7` | `KitQuasar8` |
| RuneW1sp | `RUNEW1SP` | `U38-44-3R` | `711818` | `RuneWisp38` | `WispRune9` |
| Solst1ce | `SOLST1CE` | `U39-44-3R` | `711919` | `Solstice39` | `SticeSol1` |
| TidalNyx | `TIDALNYX` | `U40-44-3R` | `712020` | `TidalNyx40` | `NyxTidal2` |

