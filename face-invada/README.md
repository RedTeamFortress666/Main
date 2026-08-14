# FACE INVADA — 5 Days a Stranger

Android-first motel mystery. **Face Invada** (Italy, 46, Silat & Blade) is trapped in the Neon Arms. Each night is a LOOK / TALK / TAKE / USE case in the spirit of classic adventure games (original plot — not a remake). Close the case, then beat-box fight that night's enemy.

| Night | Mystery | Enemy |
|---|---|---|
| 1 | Locked lobby | THE BELLHOP (Vinyl) |
| 2 | Missing mixtape | KARA DROP |
| 3 | Bloody bassline | BASS WIDOW |
| 4 | Silent witness | MC RIVET |
| 5 | The Stranger | THE STRANGER |

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

## Controls (on-screen pad always shown)

**Mystery**

| Button | Action |
|---|---|
| LOOK | Inspect a tapped hotspot (Z) |
| TALK | Speak to a person (X) |
| TAKE | Pick up after LOOK (C) |
| USE | Use the selected inventory item (V) |
| LEFT / RIGHT | Change rooms |
| UP | Case journal |
| START | Fight if the case is closed, else journal |
| Tap canvas | Apply the current verb to a hotspot / select inventory |

**Fight** (after the case is closed)

| Button | Action |
|---|---|
| PUNCH / KICK / BLADE / BASS | Hit that lane on the beat |
| BASS (meter full) | Beat Box Drop super |

