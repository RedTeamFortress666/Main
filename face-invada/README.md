# FACE INVADA — 5 Days a Stranger

Android-first motel mystery. **Face Invada** (Italy, 37, Silat & Blade) — flat cap, round shades, periwinkle scarf, dual karambits — is trapped in the Neon Arms. Walk the rooms, close a LOOK / TALK / TAKE / USE case each night, then beat-box fight that night's enemy.

| Night | Mystery | Enemy |
|---|---|---|
| 1 | Distract Vinyl with hall wax, steal the keycard, PIN 333 | THE BELLHOP |
| 2 | Kara's driver, unscrew the vent, play the tape last | KARA DROP |
| 3 | Hook the ring, read MARCO on the mirror | BASS WIDOW |
| 4 | Thaw the receipt, stamp 3:33 on the cameras | MC RIVET |
| 5 | Diary password THROUGH, speak it, open the sigil | THE STRANGER |

## Play (web)

```bash
cd face-invada
python3 -m http.server 4174 --bind 0.0.0.0
```

Open `http://localhost:4174`.

## Android

```bash
cd face-invada
ANDROID_HOME=$HOME/android-sdk ./native/build-android.sh
```

APK: `downloads/FaceInvadaBeatBoxing.apk`.

## Controls

**Mystery** — log and inventory sit at the **top** so the pad does not cover them.

| Button | Action |
|---|---|
| WALK (LEFT/RIGHT) | Walk Face Invada. Walk off an edge to change rooms |
| DO (DOWN) | Act on the nearest hotspot |
| FILE (UP) | Case journal + clues |
| LOOK / TALK / TAKE / USE | Verbs (Z X C V) |
| Tap a hotspot | Walk there, then apply the current verb |
| START | Fight only after the case is closed |

**Fight**

| Button | Action |
|---|---|
| PUNCH / KICK / BLADE / BASS | Hit that lane |
| BASS (meter full) | Beat Box Drop |
