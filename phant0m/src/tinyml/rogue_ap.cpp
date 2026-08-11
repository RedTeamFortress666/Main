#include "rogue_ap.h"
#include <config.h>
#include <Arduino.h>
#include <string.h>

#if PHANT0M_ENABLE_WIFI
#include <WiFi.h>
#endif

namespace phant0m {
namespace tinyml {
namespace {

// Q7 fixed-point logistic weights (trained offline on lab evil-twin traces).
// Features: bias, rssi_n, ch_edge, low_ent, beacon_anom, oui_rare, hidden
constexpr int16_t W_Q7[] = {
    -147,  // bias
    -109,  // rssi
      51,  // channel edge
      70,  // low SSID entropy
     141,  // beacon anomaly
     122,  // rare OUI
      96,  // hidden SSID
};

// Cheap sigmoid in Q15 → probability in Q15 (0..32767).
int16_t sigmoid_q15(int32_t x_q7) {
  // Clamp and use linear pieces to avoid libm.
  if (x_q7 > 640) return 32767;
  if (x_q7 < -640) return 0;
  // p ≈ 1/2 + x/4 for small x (x in Q7).
  int32_t p = 16384 + (x_q7 * 64);  // scale into Q15-ish
  if (p < 0) p = 0;
  if (p > 32767) p = 32767;
  return static_cast<int16_t>(p);
}

uint8_t ssid_entropy8(const char *ssid, uint8_t len) {
  if (!len) return 0;
  uint8_t seen[16] = {0};
  uint8_t uniq = 0;
  for (uint8_t i = 0; i < len; ++i) {
    const uint8_t b = static_cast<uint8_t>(ssid[i]) & 0x0f;
    if (!seen[b]) {
      seen[b] = 1;
      ++uniq;
    }
  }
  return static_cast<uint8_t>((uniq * 255) / 16);
}

bool oui_rare(const uint8_t bssid[6]) {
  if (bssid[0] & 0x02) return true;
  const uint32_t oui =
      (uint32_t(bssid[0]) << 16) | (uint32_t(bssid[1]) << 8) | bssid[2];
  return (oui == 0x000000) || (oui == 0xFFFFFF) || ((oui & 0xFF0000) == 0xDE0000);
}

}  // namespace

void begin() {}

RogueVerdict score(const ApFeature *aps, uint8_t count) {
  RogueVerdict best{0, false, 0};
  for (uint8_t i = 0; i < count; ++i) {
    const ApFeature &a = aps[i];
    // rssi -90..-30 → 0..127 Q7
    int32_t rssi_n = (static_cast<int32_t>(a.rssi) + 90) * 127 / 60;
    if (rssi_n < 0) rssi_n = 0;
    if (rssi_n > 127) rssi_n = 127;
    const int32_t ch_edge = (a.channel <= 1 || a.channel >= 11) ? 127 : 0;
    const int32_t ent_n = 127 - (static_cast<int32_t>(a.ssid_entropy) / 2);
    const int32_t hidden = (a.ssid_len == 0) ? 127 : 0;
    int32_t z = W_Q7[0];
    z += (W_Q7[1] * rssi_n) >> 7;
    z += (W_Q7[2] * ch_edge) >> 7;
    z += (W_Q7[3] * ent_n) >> 7;
    z += (W_Q7[4] * (a.beacon_anom ? 127 : 0)) >> 7;
    z += (W_Q7[5] * (a.oui_rare ? 127 : 0)) >> 7;
    z += (W_Q7[6] * hidden) >> 7;
    const int16_t p = sigmoid_q15(z);
    if (static_cast<uint16_t>(p) > best.score_q15) {
      best.score_q15 = static_cast<uint16_t>(p);
      best.ap_index = i;
      // ROGUE_SCORE_FLAG is float threshold; compare in Q15 domain.
      best.flagged = best.score_q15 >= 20316;  // ~0.62 * 32767
    }
  }
  return best;
}

void extract_from_scan(ApFeature *out, uint8_t *count, uint8_t max_count) {
  *count = 0;
#if PHANT0M_ENABLE_WIFI
  const int n = WiFi.scanNetworks(false, true);
  const int lim = n < max_count ? n : max_count;
  for (int i = 0; i < lim; ++i) {
    ApFeature &f = out[*count];
    memset(&f, 0, sizeof(f));
    f.rssi = static_cast<int8_t>(WiFi.RSSI(i));
    f.channel = static_cast<uint8_t>(WiFi.channel(i));
    String ssid = WiFi.SSID(i);
    f.ssid_len = ssid.length() > 32 ? 32 : static_cast<uint8_t>(ssid.length());
    memcpy(f.ssid, ssid.c_str(), f.ssid_len);
    f.ssid_entropy = ssid_entropy8(f.ssid, f.ssid_len);
    const uint8_t *bssid = WiFi.BSSID(i);
    if (bssid) memcpy(f.bssid, bssid, 6);
    f.oui_rare = oui_rare(f.bssid) ? 1 : 0;
    f.beacon_anom =
        (WiFi.encryptionType(i) == WIFI_AUTH_OPEN && f.ssid_len > 0) ? 1 : 0;
    ++(*count);
  }
  WiFi.scanDelete();
#else
  (void)out;
  (void)max_count;
#endif
}

// Feed pre-scanned AP records (field mode without WiFi stack linked).
void ingest_records(ApFeature *out, uint8_t *count, const ApFeature *in,
                    uint8_t in_count, uint8_t max_count) {
  const uint8_t n = in_count < max_count ? in_count : max_count;
  memcpy(out, in, sizeof(ApFeature) * n);
  *count = n;
}

}  // namespace tinyml
}  // namespace phant0m
