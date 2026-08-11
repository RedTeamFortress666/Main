# GAME ØVER! Red Team Fortress

Mobile-first **authorized engagement console** for Red Team Fortress.

## Operators

| Username | Password | Vault code |
|----------|----------|------------|
| `SpamKat2` | `Ev1lSchm33` | `W1-66-3R` |
| `Gam3.0n` | `Dig1tal.Ra1n99` | `B1-66-3R` |

After login, open **Vault** → enter your operator unlock code → **Enter AIR Console** for the offline local LLM bridge (Ollama / LM Studio / Gemma abliterated / Heretic GGUF).

## Download APK

Debug APK (Tesla-coil launcher icon):

- Repo path: [`releases/GAME-OVER-Red-Team-Fortress-debug.apk`](./releases/GAME-OVER-Red-Team-Fortress-debug.apk)

Rebuild:

```bash
npm install
export ANDROID_HOME=$HOME/android-sdk   # or your SDK path
npm run apk:debug
```

## Web / Android

```bash
npm run dev      # http://localhost:5173
npm run test
npm run lint
npm run build
npx cap sync android
```

## Safety

Control-plane UI with simulated attack actions. AIR talks to a **local** Ollama-compatible endpoint by default. Authorized research only.
