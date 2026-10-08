#pragma once

// Phant0m F1rmwar3 — ESP32 CYD portable PQC field tool
// Authorized security research / red-team lab use only.

#ifndef PHANT0M_ENABLE_WIFI
#define PHANT0M_ENABLE_WIFI 1
#endif
#ifndef PHANT0M_ENABLE_BLE
#define PHANT0M_ENABLE_BLE 0
#endif
#ifndef PHANT0M_ENABLE_MQTT
#define PHANT0M_ENABLE_MQTT 1
#endif
#ifndef PHANT0M_ENABLE_TINYML
#define PHANT0M_ENABLE_TINYML 1
#endif
#ifndef PHANT0M_ENABLE_DISPLAY
#define PHANT0M_ENABLE_DISPLAY 0
#endif
#ifndef PHANT0M_MODE_SOLAR
#define PHANT0M_MODE_SOLAR 1
#endif

// --- CYD (ESP32-2432S028R) pins ---
// Solar voltage divider on P3 IO35 (ADC1_CH7, input-only).
#define PIN_SOLAR_ADC        35
// On-board LDR (GPIO34) used as secondary entropy / ambient channel.
#define PIN_LDR_ADC          34
// Floating/noise ADC (reuse touch IRQ line only when display path idle).
#define PIN_NOISE_ADC        36
// RGB LED (active LOW) — status only, no heavy UI.
#define PIN_LED_R            4
#define PIN_LED_G            16
#define PIN_LED_B            17
#define PIN_TFT_BL           21

// --- Radio / identity ---
#define PHANT0M_SSID_PREFIX  "PH0M-"
#define PHANT0M_BLE_NAME     "PH0M-PQC"
#define PHANT0M_CHANNEL      6
#define PHANT0M_BEACON_MS    4000

// --- MQTT QKD-style key sync (field broker) ---
#ifndef PHANT0M_MQTT_HOST
#define PHANT0M_MQTT_HOST    "192.168.4.1"
#endif
#ifndef PHANT0M_MQTT_PORT
#define PHANT0M_MQTT_PORT    1883
#endif
#define PHANT0M_MQTT_TOPIC_PUB  "phant0m/qkd/out"
#define PHANT0M_MQTT_TOPIC_SUB  "phant0m/qkd/in"
#define PHANT0M_MQTT_CLIENT_ID  "ph0m-cyd"

// --- Power (solar / off-grid) ---
#define SOLAR_MV_FULL        4500
#define SOLAR_MV_LOW         3200
#define SOLAR_MV_CRIT        2800
#define SLEEP_MS_FULL        2000
#define SLEEP_MS_LOW         8000
#define SLEEP_MS_CRIT        30000
#define CPU_MHZ_SOLAR        80

// --- TinyML rogue-AP thresholds (logistic features) ---
#define ROGUE_SCORE_FLAG     0.62f
#define WIFI_SCAN_MAX_APS    16

// Flash image hard ceiling for field envs.
#define PHANT0M_FLASH_BUDGET  (256 * 1024)
