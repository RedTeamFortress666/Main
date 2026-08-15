# CRYPT3X OS boot animation

5.5s sequence at 24 fps:

1. Crest + rotating gears with mechanical clicks (~3s)
2. Keyhole of light blooms in the center (~1.2s)
3. Pale card, black type: **Brought to you by GÅMÊ ØVĒR** (~1.3s)

```bash
python3 device_r36s_polybius/media/render_bootanim.py
```

Writes:

- `media/bootanimation.zip` — Android boot animation (640×480, STORE)
- `/opt/cursor/artifacts/crypt3x_os_boot.mp4` — preview with click audio

`bootanimation.zip` is gitignored (≈60MB of uncompressed PNGs). Rebuild before
`apply.sh` or a ROM image build.
