#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

namespace phant0m {

enum class LedState : uint8_t {
  Off = 0,
  Idle,
  Handshake,
  Rogue,
  LowPower,
  Error
};

struct SolarSample {
  uint16_t solar_raw;
  uint16_t ldr_raw;
  uint16_t noise_raw;
  uint16_t solar_mv;
  uint32_t variance;
};

struct ApFeature {
  int8_t rssi;
  uint8_t channel;
  uint8_t ssid_len;
  uint8_t ssid_entropy;   // 0-255 rough char entropy
  uint8_t beacon_anom;    // 0/1 unusual interval / hidden
  uint8_t oui_rare;       // 0/1 non-common OUI nibble pattern
  char ssid[33];
  uint8_t bssid[6];
};

struct RogueVerdict {
  uint16_t score_q15;  // 0..32767 (~probability)
  bool flagged;
  uint8_t ap_index;
};

struct PqcSession {
  uint8_t pk[800];
  uint8_t sk[1632];
  uint8_t ct[768];
  uint8_t ss[32];
  bool has_keys;
  bool has_shared;
};

struct QkdSyncFrame {
  uint8_t key_id[16];
  uint8_t ss[32];
  uint32_t seq;
  uint16_t solar_mv;
  uint8_t flags;
};

}  // namespace phant0m
