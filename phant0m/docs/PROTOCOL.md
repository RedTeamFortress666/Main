# Phant0m field protocol notes

## UART radio bridge (`solar` env)

### PQC beacon frame

| Offset | Size | Field |
| --- | --- | --- |
| 0 | 1 | `0xB0` |
| 1 | 1 | `0xEA` |
| 2 | 1 | magic0 `0xF1` |
| 3 | 1 | magic1 `0x51` |
| 4 | 8 | SHA3-256(pk)[:8] |
| 12 | 1 | chunk index |
| 13 | 16 | pk chunk |

An external WiFi/BLE bridge re-emits these as softAP hostnames or BLE manufacturer data.

### QKD sync frame

| Offset | Size | Field |
| --- | --- | --- |
| 0 | 1 | `0xA5` |
| 1 | 1 | `0x5A` |
| 2 | 16 | key_id = SHAKE256(ss) |
| 18 | 32 | shared secret |
| 50 | 4 | seq (LE) |
| 54 | 2 | solar_mv |
| 56 | 1 | flags |

MQTT topics (native WiFi builds): `phant0m/qkd/out`, `phant0m/qkd/in`.
