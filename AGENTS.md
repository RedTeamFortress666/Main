# AGENTS.md

## Cursor Cloud specific instructions

This repo is a monorepo with **three independent products**:

1. **Root Tasks app** (`/`) — a Vite + React + TypeScript single-page app. No backend/database.
2. **`polybius/`** — a Flutter cross-platform app (a covert cipher tool disguised as a retro arcade shooter). Runs on web + mobile/desktop; in this cloud VM we run the **web** target.
3. **`doomsday_clock/`** — Døømsday Journal, a Flutter calendar/journal (local only, no AI backend). Web on port **8090**.

Dependencies for both are refreshed automatically on startup via the update script (`npm install` at root, `flutter pub get` in `polybius/`).

### Root Tasks app (React)
- Package manager: npm (see `package-lock.json`).
- Dev server: `npm run dev` (Vite, serves on `http://localhost:5173`, bound to `0.0.0.0`). It does not print a proxy-clickable URL — use port 5173.
- Lint / test / build live in `package.json` scripts: `npm run lint`, `npm run test` (Vitest, non-watch), `npm run build` (`tsc -b` then `vite build`).
- Tests run under jsdom via Vitest; global test APIs and `@testing-library/jest-dom` matchers are enabled through `vite.config.ts` and `src/test/setup.ts`.

### Polybius app (Flutter)
- The Flutter SDK is provisioned in the VM at `/opt/flutter` (version **3.44.8**, Dart **3.12.2** — this specific version is required because `polybius/pubspec.yaml` pins `sdk: ^3.12.2`). `/opt/flutter/bin` is on `PATH` via `~/.bashrc`, and `CHROME_EXECUTABLE=/usr/local/bin/google-chrome` is exported there too. If `flutter` is not found, use the absolute path `/opt/flutter/bin/flutter`.
- Standard commands (run from inside `polybius/`): `flutter pub get`, `flutter analyze` (lint), `flutter test`, `flutter build web`. See `polybius/README.md` for the full command list and unlock rituals.
- `flutter analyze` reports ~12 pre-existing **info-level** lints (no errors/warnings) — that is the expected clean baseline, not a regression.
- **Running the web app:** use the headless `web-server` device, not the `chrome` device:
  `cd polybius && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`
  The first compile is slow (~20–40s) and the page is blank/black until it finishes — be patient. Then open `http://localhost:8080`.
- **Login:** the app opens on a login gate. The bootstrapped account is username `DEVELOPER` / password `developer` (username is case-sensitive uppercase). After login you land on the neon arcade main menu.

### Døømsday Journal (`doomsday_clock/`)
- Local Flutter calendar/journal. No backend.
- Run web: `cd doomsday_clock && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8090` then open `http://localhost:8090`.
- Tests: `flutter test` and `flutter analyze` from `doomsday_clock/`.
- Android APK (arm64): `doomsday_clock/releases/doomsday-journal-3.0.1-android-arm64.apk`.
This repo contains two separate products:

1. **Root React app** (`/`) — a small Vite + React + TypeScript frontend (`name: first-app`). No backend/database.
2. **`polybius/`** — a Flutter app ("PØLYBĪUS", a retro neon arcade shooter that is actually covert encrypted messaging). This is the substantial product. See `polybius/README.md`.

Dependencies for both are refreshed automatically on startup via the update script (`npm install` at the root, `flutter pub get` in `polybius`).

### Root React app

- Package manager: npm (see `package-lock.json`).
- Dev server: `npm run dev` (Vite, serves on `http://localhost:5173`). It does not print a URL you can click through a proxy — use port 5173.
- Lint / test / build commands live in `package.json` scripts: `npm run lint`, `npm run test` (Vitest, non-watch), `npm run build` (runs `tsc -b` then `vite build`).
- Tests run under jsdom via Vitest; global test APIs and `@testing-library/jest-dom` matchers are enabled through `vite.config.ts` and `src/test/setup.ts`.

### `polybius/` Flutter app

- The Flutter SDK (stable 3.44.8, Dart 3.12.2 — matches `pubspec.yaml`'s `sdk: ^3.12.2`) is installed at `~/flutter` and added to `PATH` via `~/.bashrc`. If `flutter` is not found, run `export PATH="$HOME/flutter/bin:$PATH"`.
- Standard commands (run from inside `polybius/`): `flutter pub get`, `flutter test`, `flutter analyze` (lint), `flutter build web` / `flutter run`. See `polybius/README.md` for build targets and the cipher/unlock details.
- `flutter analyze` currently reports only pre-existing `info`-level lints (no errors) — that is the expected baseline.
- Only the **web** toolchain is set up (Chrome is present). Android/iOS/Linux-desktop toolchains are intentionally not installed (`flutter doctor` will flag them). To run/see the app, serve web: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`, then open `http://localhost:8080` (the `web-server` device compiles for ~15-20s before it is served; a Dart Debug Chrome extension warning is normal and harmless).
- First login (bootstrapped on first install): username `DEVELOPER`, password `developer`. Login lands on the neon arcade main menu; `START GAME` launches the Flame space shooter. The hidden cipher layer requires the unlock rituals documented in `polybius/README.md`.

### `doomsday_clock/` Døømsday Journal

- Local calendar/journal. No backend.
- Run web: `cd doomsday_clock && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8090`, then open `http://localhost:8090`.
- Tests: `flutter test` and `flutter analyze` from `doomsday_clock/`.
- Android APK (arm64): `doomsday_clock/releases/doomsday-journal-3.0.1-android-arm64.apk`.
