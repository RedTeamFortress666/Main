# PØLYBÎŪS — Ritual & Credentials Test Matrix

**Audience:** you (tester) — mark PASS / FAIL / NOTES after each check.  
**Builds:** reinstall fresh APKs from this branch so wave-3 accounts bootstrap.  
**Important:** on an old install, new accounts appear only after a fresh install (or clear app data). Existing accounts keep prior passwords.

---

## A. Login rituals (what to do)

### A1. PORTAL APK (`PØLYBÎŪS PORTAL`)

1. Cold start → Layer-1 login (username + password). If prompted, enter **6-digit PIN**.
2. Arcade menu → **SETTINGS** → difficulty **11** (blank cell) → **LANGUAGES** → **Russian**.
3. **START GAME** → die early (level &lt; 3 or &lt; 6 kills).
4. Hold **GAME OVER** ~6s → ERROR screen.
5. Type ≥6 words in “describe incident” → hold **SAVE AS DRAFT** → **SEND**.  
   *(Diagnostic / invite box under the incident field is **not** required.)*
6. **DEV ACCESS PORTAL** → username + password + **DEV CODE** (see tables).
7. Expect cipher (ENCRYPT / DECRYPT / POOL / SYNC / CONNECT). Admins/devs with B1/D1/W1 get HQ tools.

### A2. USER APK (`PØLYBÎŪS V.1`)

1. Cold start → **arcade menu** (START / LOAD / HIGH SCORE / SETTINGS) — not auto-play.
2. **START GAME** → die early (level &lt; 3 or &lt; 6 kills).
3. Hold **GAME OVER** ~6s → ERROR → ≥6 words → hold **SAVE AS DRAFT** → **SEND**.
4. **USER ACCESS PORTAL** → username + password + **ACCESS CODE** (= that account’s invite / game code).
5. Expect cipher tabs ENCRYPT / DECRYPT / SYNC / CONNECT (**no POOL**).  
   Dev/admin accounts still log in; unlock is user-tier on this APK.

### A3. Codes cheat-sheet

| Code family | Who may use | PORTAL grant | USER grant |
| --- | --- | --- | --- |
| `B1-66-3R` / `D1-66-3R` / `W1-66-3R` | admin or developer only | developer + HQ | user unlock only |
| Account invite (e.g. `GC7-66-3R`) | that operator (or any seeded invite) | agents → user; admin/dev → developer | user unlock |
| `TR1-66-3R` | same as invite | as above | user unlock |
| ~~`DEVELOPER` / `developer`~~ | — | **STRICKEN** | **STRICKEN** |

**Gl1tchCat example (USER):** username `Gl1tchCat` (or `GL1TCHCAT`), password `CatGlitch1`, access code `GC7-66-3R`. After login you should land in cipher (PIN gate must not bounce you to menu).

**Art3mas alias:** display name `Art3mas` resolves to username `ARTEM3S`.

---

## B. Existing named operators

| Display | Username | Tier | Invite / Dev code | PIN | Password | Temp / backup | PORTAL | USER |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RedTeam01 | REDTEAM01 | admin | B1-66-3R | 816639 | 816639 | 816639* | ☐ | ☐ |
| SpamKat2 | SPAMKAT2 | developer | W1-66-3R | 810739 | Ev1l-Schm33 | LilB1tScary99 | ☐ | ☐ |
| Gam3.0n | GAM3.0N | developer | B1-66-3R | 816639 | Dig1tal.Ra1n99 | 01-p0lyb1u5-10 | ☐ | ☐ |
| KASP3R | KASP3R | admin | TR1-66-3R | 791639 | BurnHideFr13d | P1ckl3M0rty69 | ☐ | ☐ |
| T3mptress | T3MPTRESS | agent | 80-081-35 | 808135 | not1nkansas69 | NoPlaceL1ke | ☐ | ☐ |
| CrownOfCorns | CROWNOFCORNS | admin | C0-9N-3E | 539667 | 20YokoMicrowave14 | C0rnS1lo14 | ☐ | ☐ |
| MizzPickl3s | MIZZPICKL3S | agent | SP-1N-33 | 080826 | 8-Bit.Bitch3s | Glitch.B1tch99 | ☐ | ☐ |
| P!k.ZuP | P!K.ZUP | admin | D4-N6-3R | 839093 | DocCh1ck3n | TakeAOrdaPr33z | ☐ | ☐ |

\*RedTeam01 has no separate backup hash on some installs — use `816639` for both.

Shared privileged codes (PORTAL HQ): `B1-66-3R`, `D1-66-3R`, `W1-66-3R` (privileged accounts only).

---

## C. Existing BETA pool (10)

| Display | Username | Tier | Invite | PIN | Password | Backup | PORTAL | USER |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| NiteQueen | NITEQUEEN | admin | NQ1-66-3R | 314159 | NiteOwl42 | NightOwl7 | ☐ | ☐ |
| Art3mas | ARTEM3S | admin | AR2-66-3R | 271828 | BowArrow7 | Huntress9 | ☐ | ☐ |
| Cup1d! | CUP1D! | agent | CU3-66-3R | 161803 | LoveShot99 | CupidsBow1 | ☐ | ☐ |
| Dyslex1c | DYSLEX1C | agent | DX4-66-3R | 141421 | SpellMix8 | LexiFix99 | ☐ | ☐ |
| WhyTwoK | WHYTWOK | agent | Y2K-66-3R | 173205 | PartyY2K1 | TwoKWave2 | ☐ | ☐ |
| M00nFox | M00NFOX | agent | MF5-66-3R | 223606 | MoonRun88 | FoxMoon11 | ☐ | ☐ |
| V3ctorKid | V3CTORKID | agent | VK6-66-3R | 244949 | VecTor99 | KidVector3 | ☐ | ☐ |
| Gl1tchCat | GL1TCHCAT | agent | GC7-66-3R | 264575 | CatGlitch1 | GlitchMe2 | ☐ | ☐ |
| H0neyBad | H0NEYBAD | agent | HB8-66-3R | 331127 | HoneyRun7 | BadHoney9 | ☐ | ☐ |
| PixelW1z | PIXELW1Z | agent | PW9-66-3R | 367879 | PixelZap12 | WizPixel5 | ☐ | ☐ |

---

## D. Wave 2 — 5 new admins

| Display | Username | Invite | PIN | Password | Temp / backup | PORTAL | USER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Bl4deRun | BL4DERUN | BR1-77-3R | 401122 | BladeCut99 | RunBlade7 | ☐ | ☐ |
| S0larF1x | S0LARF1X | SF2-77-3R | 412233 | SolarFix88 | FixSolar3 | ☐ | ☐ |
| Qu4ntumOwl | QU4NTUMOWL | QO3-77-3R | 423344 | OwlQuant1 | QuantOwl9 | ☐ | ☐ |
| IronMer1d | IRONMER1D | IM4-77-3R | 434455 | IronTide42 | MeridIron5 | ☐ | ☐ |
| NeonVult | NEONVULT | NV5-77-3R | 445566 | VultNeon77 | NeonNest2 | ☐ | ☐ |

---

## E. Wave 2 — 3 new developers

| Display | Username | Invite | PIN | Password | Temp / backup | PORTAL (+ B1/D1/W1 OK) | USER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C0deRaven | C0DERAVEN | CR1-88-3R | 501177 | RavenCode9 | CodeNest1 | ☐ | ☐ |
| NullPtrX | NULLPTRX | NP2-88-3R | 512288 | NullSeg88 | PtrNull3 | ☐ | ☐ |
| HexWraith | HEXWRAITH | HW3-88-3R | 523399 | HexGhost7 | WraithHex2 | ☐ | ☐ |

---

## F. Wave 2 — 20 new users (agents)

| Display | Username | Invite | PIN | Password | Temp / backup | PORTAL | USER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AshK1te | ASHK1TE | U01-55-3R | 600101 | AshKite11 | KiteAsh2 | ☐ | ☐ |
| B1tR0ver | B1TR0VER | U02-55-3R | 600202 | BitRover22 | RoverBit8 | ☐ | ☐ |
| Cry0Moth | CRY0MOTH | U03-55-3R | 600303 | CryoMoth3 | MothCryo9 | ☐ | ☐ |
| Dr1ftFox | DR1FTFOX | U04-55-3R | 600404 | DriftFox4 | FoxDrift1 | ☐ | ☐ |
| Ech0Lynx | ECH0LYNX | U05-55-3R | 600505 | EchoLynx5 | LynxEcho7 | ☐ | ☐ |
| FlareM1nt | FLAREM1NT | U06-55-3R | 600606 | FlareMint6 | MintFlare2 | ☐ | ☐ |
| Gl0wWire | GL0WWIRE | U07-55-3R | 600707 | GlowWire7 | WireGlow3 | ☐ | ☐ |
| H4zeP1x | H4ZEP1X | U08-55-3R | 600808 | HazePix88 | PixHaze4 | ☐ | ☐ |
| IvyR0cket | IVYR0CKET | U09-55-3R | 600909 | IvyRocket9 | RocketIvy5 | ☐ | ☐ |
| J3tC0il | J3TC0IL | U10-55-3R | 601010 | JetCoil10 | CoilJet6 | ☐ | ☐ |
| Krypt0Bee | KRYPT0BEE | U11-55-3R | 601111 | KryptoBee1 | BeeKrypt7 | ☐ | ☐ |
| LumenRay | LUMENRAY | U12-55-3R | 601212 | LumenRay12 | RayLumen8 | ☐ | ☐ |
| Mir4geCat | MIR4GECAT | U13-55-3R | 601313 | MirageCat3 | CatMirage9 | ☐ | ☐ |
| N0vaQuill | N0VAQUILL | U14-55-3R | 601414 | NovaQuill4 | QuillNova1 | ☐ | ☐ |
| Orb1tWisp | ORB1TWISP | U15-55-3R | 601515 | OrbitWisp5 | WispOrbit2 | ☐ | ☐ |
| Pr1smDawn | PR1SMDAWN | U16-55-3R | 601616 | PrismDawn6 | DawnPrism3 | ☐ | ☐ |
| QuarkM1nt | QUARKM1NT | U17-55-3R | 601717 | QuarkMint7 | MintQuark4 | ☐ | ☐ |
| R1ftSpark | R1FTSPARK | U18-55-3R | 601818 | RiftSpark8 | SparkRift5 | ☐ | ☐ |
| SynthOwl | SYNTHOWL | U19-55-3R | 601919 | SynthOwl19 | OwlSynth6 | ☐ | ☐ |
| Tachyon | TACHY0N | U20-55-3R | 602020 | TachyOn20 | OnTachy7 | ☐ | ☐ |

---

## G. Ritual smoke checklist

| # | Check | Expected | Result |
| --- | --- | --- | --- |
| G1 | USER splash → menu | START / LOAD visible, not in-game | ☐ |
| G2 | USER early death → hold GAME OVER | ERROR screen | ☐ |
| G3 | USER Gl1tchCat portal login | Lands in cipher (not stuck on PIN→menu) | ☐ |
| G4 | PORTAL RedTeam01 Layer-1 + ritual + B1 | Cipher + HQ/POOL | ☐ |
| G5 | PORTAL agent with own invite | Cipher, no HQ panel | ☐ |
| G6 | Agent using B1 on portal | ACCESS DENIED | ☐ |
| G7 | DEVELOPER / developer | STRICKEN | ☐ |
| G8 | Wave2 user U01 on USER APK | Cipher after ritual | ☐ |
| G9 | Wave2 developer on PORTAL with W1 | Developer unlock | ☐ |
| G10 | Art3mas display-name login | Works as ARTEM3S | ☐ |
| G11 | Wave3 admin V0ltStag on PORTAL | Layer-1 login + PIN `701122` | ☐ |
| G12 | Wave3 user Aur0raFox on USER APK | Cipher after ritual (`U21-44-3R`) | ☐ |
| G13 | Wave3 developer B1tF0rge backup pw | `ForgeBit2` logs in on PORTAL | ☐ |

---

## I. Wave 3 — 5 new admins

| Display | Username | Invite | PIN | Password | Temp / backup | PORTAL | USER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| V0ltStag | V0LTSTAG | VS1-99-3R | 701122 | VoltStag91 | StagVolt3 | ☐ | ☐ |
| Cr1ms0nRx | CR1MS0NRX | CX2-99-3R | 712233 | CrimsonRx2 | RxCrimson8 | ☐ | ☐ |
| Obs1dian | OBS1DIAN | OD3-99-3R | 723344 | Obsidian77 | DianObsi5 | ☐ | ☐ |
| StormK3l | STORMK3L | SK4-99-3R | 734455 | StormKel44 | KelStorm6 | ☐ | ☐ |
| ApexW0lf | APEXW0LF | AW5-99-3R | 745566 | ApexWolf9 | WolfApex1 | ☐ | ☐ |

---

## J. Wave 3 — 3 new developers

| Display | Username | Invite | PIN | Password | Temp / backup | PORTAL (+ B1/D1/W1 OK) | USER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B1tF0rge | B1TF0RGE | BF1-00-3R | 801177 | BitForge91 | ForgeBit2 | ☐ | ☐ |
| GhostAsm | GHOSTASM | GA2-00-3R | 812288 | GhostAsm8 | AsmGhost4 | ☐ | ☐ |
| Zer0Kern | ZER0KERN | ZK3-00-3R | 823399 | ZeroKern7 | KernZero3 | ☐ | ☐ |

---

## K. Wave 3 — 20 new users (agents)

| Display | Username | Invite | PIN | Password | Temp / backup | PORTAL | USER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Aur0raFox | AUR0RAFOX | U21-44-3R | 710101 | AuroraFx21 | FoxAurora1 | ☐ | ☐ |
| B0real1s | B0REAL1S | U22-44-3R | 710202 | Borealis22 | LisBorea2 | ☐ | ☐ |
| C1nderSki | C1NDERSKI | U23-44-3R | 710303 | CinderSki3 | SkiCinder3 | ☐ | ☐ |
| DuskRav3n | DUSKRAV3N | U24-44-3R | 710404 | DuskRaven4 | RavenDusk4 | ☐ | ☐ |
| EmberLynx | EMBERLYNX | U25-44-3R | 710505 | EmberLynx5 | LynxEmber5 | ☐ | ☐ |
| FrostW1sp | FROSTW1SP | U26-44-3R | 710606 | FrostWisp6 | WispFrost6 | ☐ | ☐ |
| Gild3dFin | GILD3DFIN | U27-44-3R | 710707 | GildedFin7 | FinGilded7 | ☐ | ☐ |
| Hal0Drift | HAL0DRIFT | U28-44-3R | 710808 | HaloDrift8 | DriftHalo8 | ☐ | ☐ |
| IrisNova | IRISNOVA | U29-44-3R | 710909 | IrisNova29 | NovaIris9 | ☐ | ☐ |
| Jad3Spark | JAD3SPARK | U30-44-3R | 711010 | JadeSpark0 | SparkJade1 | ☐ | ☐ |
| K0iWave | K0IWAVE | U31-44-3R | 711111 | KoiWave31 | WaveKoi2 | ☐ | ☐ |
| LunarB1t | LUNARB1T | U32-44-3R | 711212 | LunarBit32 | BitLunar3 | ☐ | ☐ |
| MystW1re | MYSTW1RE | U33-44-3R | 711313 | MystWire33 | WireMyst4 | ☐ | ☐ |
| NyxFlare | NYXFLARE | U34-44-3R | 711414 | NyxFlare34 | FlareNyx5 | ☐ | ☐ |
| OpalR1ft | OPALR1FT | U35-44-3R | 711515 | OpalRift35 | RiftOpal6 | ☐ | ☐ |
| PulseF0x | PULSEF0X | U36-44-3R | 711616 | PulseFox36 | FoxPulse7 | ☐ | ☐ |
| QuasarK1t | QUASARK1T | U37-44-3R | 711717 | QuasarKit7 | KitQuasar8 | ☐ | ☐ |
| RuneW1sp | RUNEW1SP | U38-44-3R | 711818 | RuneWisp38 | WispRune9 | ☐ | ☐ |
| Solst1ce | SOLST1CE | U39-44-3R | 711919 | Solstice39 | SticeSol1 | ☐ | ☐ |
| TidalNyx | TIDALNYX | U40-44-3R | 712020 | TidalNyx40 | NyxTidal2 | ☐ | ☐ |

---

## H. Downloads (this branch)

- PORTAL: `polybius/dist/polybius-v1-stable-hq-android-arm64.apk`
- V.1: `polybius/dist/polybius-v1-stable-user-android-arm64.apk`
- Raw base: `https://github.com/RedTeamFortress666/Main/raw/cursor/pool-pin-bt-ui-d8fa/`

Reply with which rows failed and what you saw (error text / screen). Fresh install recommended after this cut.

*— end test matrix —*
