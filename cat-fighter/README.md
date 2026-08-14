# Cat Fighter: Tuna vs Blue

A single-page Street Fighter-style 1v1 with cats, milk, and tuna.

Queen Yoko (black-and-white tuxedo capitalist tuna queen) versus Tsar Morlan (Russian Blue revolutionary). When the clock dies, **Stella** arrives with a log and milk. When a cat is KO'd, **Joye** — an older woman with a walker and a tin of tuna — may revive them once per cat per match.

A looping cartoon theme plays after the first key/tap. Cats **meow** when they bump and **hiss** if they collide during an attack.

## Play (PC)

Serve the folder over HTTP (ES modules):

```bash
cd cat-fighter
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Android, iPhone, PWA

Same game, three wrappers. See [`native/README.md`](native/README.md).

- **Android APK:** `./native/build-android.sh` (needs Android SDK 34). Sideload `native/CatFighter-debug.apk`.
- **iPhone:** Safari → Share → Add to Home Screen (PWA), or open `native/ios` in Xcode with a `www` folder copy of this game.
- **Touch:** phones get an on-screen pad (move / punch / kick / heavy / start).

Query flags:

- `?fasttimeout=1` — round timer starts at 8 seconds so Stella's milk sequence is easy to demo. F9 forces a timeout, F10/F11 KO P1/P2.
- `?debug=1` — same debug keys as above

## Controls

Shown in-game on the menu. Summary:

| | P1 Yoko | P2 Morlan |
|---|---|---|
| Move | WASD | Arrows |
| Block | Left Shift or hold back | Right Shift or hold back |
| Light / Medium / Heavy punch | Z X C | N M , |
| Light / Medium / Heavy kick | F G H | J K L |
| Specials | Quarter-circle + button, or DP + punch | same |
| Super | Double QCF + punch, full meter | same |

Best of 3 rounds. Lows (crouch medium/heavy kick) must be crouch-blocked. Jump attacks are overheads.

## Adding a move

1. Describe frame data in `js/logic.js` → `ATTACKS`
2. Map a motion in `CHARACTERS[id].specials`
3. Optionally add a pose in `js/render.js` (`drawFighter`)

## Layout

```
cat-fighter/
  index.html
  styles.css
  assets/          portraits + stages
  js/logic.js      pure rules (unit-tested)
  js/fighter.js    physics, attacks, projectiles
  js/game.js       screens, rounds, Stella / Joye
  js/render.js     canvas drawing
  js/audio.js      Web Audio synth
  js/input.js      keyboard + motion buffer
  js/ai.js         CPU opponent
```
