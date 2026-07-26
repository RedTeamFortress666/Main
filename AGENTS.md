# AGENTS.md

## Cursor Cloud specific instructions

This repo is a single frontend app (Vite + React + TypeScript). There is no backend/database.

- Package manager: npm (see `package-lock.json`). Dependencies are refreshed automatically on startup via the update script.
- Dev server: `npm run dev` (Vite, serves on `http://localhost:5173`). It does not print a URL you can click through a proxy — use port 5173.
- Lint / test / build commands live in `package.json` scripts: `npm run lint`, `npm run test` (Vitest, non-watch), `npm run build` (runs `tsc -b` then `vite build`).
- Tests run under jsdom via Vitest; global test APIs and `@testing-library/jest-dom` matchers are enabled through `vite.config.ts` and `src/test/setup.ts`.
