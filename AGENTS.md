# AGENTS.md

## Cursor Cloud specific instructions

This repo is a monorepo with **two independent products**:

1. **Root Tasks app** (`/`) — a Vite + React + TypeScript single-page app. No backend/database.
2. **`polybius/`** — a Flutter cross-platform app (a covert cipher tool disguised as a retro arcade shooter). Runs on web + mobile/desktop; in this cloud VM we run the **web** target.

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
