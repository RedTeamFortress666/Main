# Phant0m F1rmwar3

ESP32 **CYD** (ESP32-2432S028R) Arduino-framework firmware for a portable post-quantum cryptography field tool.

**Authorized security research / red-team lab use only.**

## Features

| Module | Role |
| --- | --- |
| **Kyber512** | Keygen + encaps/decaps (software NTT; ESP32 HW RNG + SHA3/SHAKE for entropy/KDF) |
| **Solar-entropy RNG** | ADC noise (GPIO36) + LDR (GPIO34) + solar voltage variance (GPIO35) mixed with `esp_random()` |
| **PQC beacon** | WiFi softAP / BLE adv (`wifi`/`ble` envs) or UART-bridged beacon (`solar` size build) |
| **TinyML rogue-AP flagger** | Fixed-point logistic model on scan features (no TFLite) |
| **MQTT QKD sync** | PubSubClient over WiFi, or framed UART bridge in the size build |
| **Solar power manager** | 80 MHz CPU, backlight off, duty-cycle naps, deep-sleep on critical voltage |

## Flash budget

Default field image (`solar`) is **strictly under 256 KiB**.  
`scripts/size_check.py` fails the build if the `.bin` exceeds that ceiling.

Espressif’s closed-source WiFi/BT blobs alone are larger than 256 KiB, so the size-compliant `solar` build keeps PQC / TinyML / MQTT framing / power on-chip and bridges radio via UART (`0xB0 0xEA` beacon frames, `0xA5 0x5A` QKD frames). Use `wifi` or `ble` when you can spend the flash for native stacks.

## Hardware (CYD)

| Signal | GPIO | Notes |
| --- | --- | --- |
| Solar voltage divider | 35 | ADC1, input-only (P3) |
| LDR | 34 | Secondary entropy |
| Noise ADC | 36 | Touch-IRQ line when UI idle |
| RGB LED | 4 / 16 / 17 | Active-low status |
| TFT backlight | 21 | Forced off in solar mode |

## Build

```bash
cd phant0m
pio run -e solar    # default, <256 KiB
pio run -e wifi     # native WiFi beacon + MQTT + TinyML scan
pio run -e ble      # NimBLE advertiser
pio run -e lab      # WiFi+BLE debug
pio run -e solar -t upload
pio device monitor
```

Optional STA creds for broker reachability (`wifi`/`lab`):

```ini
build_flags =
  ${env:wifi.build_flags}
  -DPHANT0M_STA_SSID=\"field-mesh\"
  -DPHANT0M_STA_PASS=\"secret\"
```

## Serial (115200)

Boot logs Kyber keygen, handshake readiness, rogue-AP scores (`score_q15`), and QKD sync frames.
