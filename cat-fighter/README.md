# Yoko's Tuna Brawl

Tekken-style 1v1 **Cat Battle** plus **Cat Car Racing**. Stella brings milk between rounds; Joye (walker, tuna) may revive a KO.

## Android

Rebuild and install the APK:

```bash
cd cat-fighter
./native/build-android.sh
```

The package is `downloads/YokosTunaBrawl.apk`.

Play in a browser while iterating:

```bash
cd cat-fighter
python3 -m http.server 4173
```

Query flags: `?fasttimeout=1` (F9 milk, F10/F11 KO).

## Games

From the title screen, **PRESS ENTER** then pick:

- **Cat Battle** — Tekken-style 4-limb brawler (Queen Yoko vs Tsar Morlan)
- **Cat Car Racing** — 3-lap oval. Heads poke out of the cars.

### Cat Battle controls

| | P1 Yoko | P2 Morlan |
|---|---|---|
| Move / crouch / jump | WASD | Arrows |
| Dash / backdash | tap forward or back twice | same |
| Block | Left Shift or hold back | Right Shift or hold back |
| Sidestep | C | , |
| Left Punch / Right Punch | Z / X | N / M |
| Left Kick / Right Kick | F / G | J / K |
| Throw | Z+X | N+M |
| Launcher | down or down-forward + RP | same |
| Rage Art | Z+G with full Rage | N+K with full Rage |

Android touch: LP RP / LK RK plus SS (sidestep), TH (throw), START.

### Cat Car Racing

| Cat | Car |
|---|---|
| Queen Yoko | Gold Rolls Royce |
| Tsar Morlan | Black hearse |
| Baby (black Maine coon, white spots) | Blue Lotus |
| Kittens (big orange Maine coon) | Red VW Beetle |

P1 Yoko: W gas, S brake, A/D steer. P2 Morlan uses arrows in VS PLAYER. CPU fills the rest.
