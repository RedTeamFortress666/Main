# Yoko's Tuna Brawl

Arcade 1v1 **Cat Battle** plus **Cat Car Racing**. On-screen Android pad: Up / Down / Left / Right, Jump, Punch, Kick, Laser Eyes. Stella brings milk between rounds; Joye may revive a KO.

Joye occasionally tosses Yoko **Capitalist Chicken**. Stella occasionally tosses Morlan **Soviet Salmon**. Either pickup grants super strength, speed, and invulnerability.

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

From the title screen, **PRESS START** then pick:

- **Cat Battle** — Queen Yoko vs Tsar Morlan. Punch, kick, jump, laser eyes.
- **Cat Car Racing** — 3-lap oval. Heads poke out of the cars.

### Cat Battle controls

| | P1 Yoko (on-screen pad) | P2 Morlan |
|---|---|---|
| Up / Down / Left / Right | D-pad | Arrows |
| Jump | JUMP (or Up) | P |
| Punch | PUNCH | N |
| Kick | KICK | M |
| Laser eyes | LASER (charges after firing) | , |
| Block | hold Back | hold Back |

Laser eyes spend the LASER meter. It wears off and refills on its own.

### Cat Car Racing

| Cat | Car |
|---|---|
| Queen Yoko | Gold Rolls Royce |
| Tsar Morlan | Black hearse |
| Baby (black Maine coon, white spots) | Blue Lotus |
| Kittens (big orange Maine coon) | Red VW Beetle |

P1 Yoko: Up gas, Down brake, Left/Right steer. P2 Morlan uses arrows in VS PLAYER. CPU fills the rest.
