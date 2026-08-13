# ESP32 ports (T-Deck / T-Embed / CYD / Cardputer)

See [`../firmware/README.md`](../firmware/README.md).

PØLYBĪUS on LilyGO T-Deck, LilyGO T-Embed (S3), CYD (Cheap Yellow Display), and
M5Stack Cardputer shares the same emoji rotor cipher as the Flutter app. Build
with PlatformIO envs `tdeck`, `tembed`, `cyd`, and `cardputer`. Host cipher
parity:

```bash
cd firmware && make test
```

Prebuilt downloads: `dist/esp32/polybius-{tdeck,tembed,cyd,cardputer}.bin`.
