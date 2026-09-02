# FACE INVADA's BEAT BOXING

Neon rhythm fighter. **Face Invada** (Italy, 46, Silat & Blade) vs **MC Rivet**.
Four lanes: Punch, Kick, Blade, Bass. Charge Bass for a Beat Box Drop.

The Android APK is a **local sideload** — not published on GitHub or a store.

## Play

```bash
cd face-invada
python3 -m http.server 4174 --bind 0.0.0.0
```

Or from the repo root: `npm run dev` then open `/face-invada/`.

- **Keyboard:** Z punch · X kick · C blade · V bass · Enter start
- **Phone:** on-screen pad (always visible)

## Sideload APK (not GitHub)

```bash
export ANDROID_HOME=$HOME/android-sdk
./native/build-android.sh
```

The script writes `downloads/FaceInvadaBeatBoxing.apk`. Open `downloads.html`
on the local server and tap **Android APK**. Allow install from this source.
