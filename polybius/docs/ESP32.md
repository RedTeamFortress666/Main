# ESP32 ports (T-Deck / T-Embed / CYD)

See [`../firmware/README.md`](../firmware/README.md).

PØLYBĪUS on LilyGO T-Deck, LilyGO T-Embed (S3), and the Cheap Yellow Display
(CYD) shares the same emoji rotor cipher as the Flutter app. Build with
PlatformIO envs `tdeck`, `tembed`, and `cyd`. Host cipher parity:

```bash
cd firmware && make test
```
