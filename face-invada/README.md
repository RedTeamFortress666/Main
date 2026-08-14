# FACE INVADA's BEAT BOXING

Neon rhythm fighter. **Face Invada** (Italy, 46, Silat & Blade) vs **MC Rivet**. Hit Punch / Kick / Blade / Bass on the beat. Fill BASS and press it off-note for a Beat Box Drop.

## Play

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

| | Action |
|---|---|
| PUNCH | Lane 1 (Z) |
| KICK | Lane 2 (X) |
| BLADE | Lane 3 (C) |
| BASS | Lane 4, or super when the meter is full (V) |
| START | Confirm / continue |
| D-pad | Character select |

On-screen pad is always shown.
