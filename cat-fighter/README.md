# Yoko's Tuna Brawl

Street Fighter-style 1v1: Queen Yoko versus Tsar Morlan. Stella brings milk on timeout; Joye (walker, tuna) may revive a KO.

## Downloads

| Platform | File |
|---|---|
| **Android APK** | [`downloads/YokosTunaBrawl.apk`](downloads/YokosTunaBrawl.apk) |
| **PC / web zip** | [`downloads/YokosTunaBrawl-web.zip`](downloads/YokosTunaBrawl-web.zip) |
| **iPhone** | Safari → Share → Add to Home Screen (PWA), or `native/ios` in Xcode |
| **In-game page** | [`downloads.html`](downloads.html) |

GitHub direct links (this branch):

- APK: https://github.com/RedTeamFortress666/Main/raw/cursor/cat-fighter-tuna-vs-blue-1050/cat-fighter/downloads/YokosTunaBrawl.apk
- PC zip: https://github.com/RedTeamFortress666/Main/raw/cursor/cat-fighter-tuna-vs-blue-1050/cat-fighter/downloads/YokosTunaBrawl-web.zip

## Play locally

```bash
cd cat-fighter
python3 -m http.server 4173
```

Then open `http://localhost:4173`. Rebuild the APK with `./native/build-android.sh`.

Query flags: `?fasttimeout=1` (F9 milk, F10/F11 KO).

## Controls

| | P1 Yoko | P2 Morlan |
|---|---|---|
| Move | WASD | Arrows |
| Block | Left Shift or hold back | Right Shift or hold back |
| Light / Medium / Heavy punch | Z X C | N M , |
| Light / Medium / Heavy kick | F G H | J K L |
| Specials | Quarter-circle + button, or DP + punch | same |
| Super | Double QCF + punch, full meter | same |
