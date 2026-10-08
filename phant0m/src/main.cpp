#include <config.h>
#include <phant0m_types.h>
#include "entropy/solar_rng.h"
#include "pqc/kyber512.h"
#include "radio/pqc_beacon.h"
#include "tinyml/rogue_ap.h"
#include "mqtt/qkd_sync.h"
#include "power/solar_pm.h"
#include "ui/status_led.h"

#include <Arduino.h>
#include <string.h>

namespace {

phant0m::PqcSession g_session{};
uint32_t g_seq = 0;
uint32_t g_last_beacon = 0;

#if !PHANT0M_ENABLE_WIFI && PHANT0M_ENABLE_TINYML
// Demo AP features for TinyML path when WiFi stack is not linked (size build).
phant0m::ApFeature g_demo_aps[2];
void load_demo_aps() {
  memset(g_demo_aps, 0, sizeof(g_demo_aps));
  g_demo_aps[0].rssi = -35;
  g_demo_aps[0].channel = 1;
  memcpy(g_demo_aps[0].ssid, "corp-wifi", 9);
  g_demo_aps[0].ssid_len = 9;
  g_demo_aps[0].ssid_entropy = 80;
  g_demo_aps[0].beacon_anom = 1;
  g_demo_aps[0].oui_rare = 1;
  g_demo_aps[0].bssid[0] = 0xDE;
  g_demo_aps[1].rssi = -70;
  g_demo_aps[1].channel = 6;
  memcpy(g_demo_aps[1].ssid, "home", 4);
  g_demo_aps[1].ssid_len = 4;
  g_demo_aps[1].ssid_entropy = 200;
}
#endif

void boot_banner() {
  Serial.begin(115200);
  delay(50);
  Serial.println(F("Phant0m F1rmwar3 " PHANT0M_VERSION));
  Serial.println(F("ESP32 CYD / Kyber512 / solar-entropy"));
  Serial.println(F("Authorized research use only."));
}

bool bring_up_pqc() {
  phant0m::kyber512::set_random(phant0m::entropy::randombytes);
  for (int i = 0; i < 8; ++i) phant0m::entropy::mix_hw();
  if (phant0m::kyber512::keygen(g_session.pk, g_session.sk) != 0) return false;
  g_session.has_keys = true;
  g_session.has_shared = false;
  return true;
}

}  // namespace

void setup() {
  boot_banner();
  phant0m::power::begin();
  phant0m::ui::begin();
  phant0m::entropy::begin();
  phant0m::tinyml::begin();
#if !PHANT0M_ENABLE_WIFI && PHANT0M_ENABLE_TINYML
  load_demo_aps();
#endif

  phant0m::ui::set(phant0m::LedState::Idle);
  if (!bring_up_pqc()) {
    Serial.println(F("Kyber keygen failed"));
    phant0m::ui::set(phant0m::LedState::Error);
    return;
  }
  Serial.print(F("Kyber512 keygen ok, entropy="));
  Serial.println(static_cast<unsigned long>(phant0m::entropy::pool_health()));

  phant0m::radio::begin(&g_session);
#if PHANT0M_ENABLE_MQTT
  phant0m::mqtt_qkd::begin();
#endif
  phant0m::ui::blink(phant0m::LedState::Handshake);
  g_last_beacon = millis();
}

void loop() {
  const phant0m::SolarSample solar = phant0m::entropy::sample();
  phant0m::power::apply_solar_profile(solar);

  if (phant0m::power::critically_low(solar)) {
    phant0m::ui::set(phant0m::LedState::LowPower);
    phant0m::radio::stop();
    phant0m::power::deep_sleep_ms(phant0m::power::next_sleep_ms(solar));
    return;
  }

  const uint32_t now = millis();
  if (now - g_last_beacon >= PHANT0M_BEACON_MS) {
    g_last_beacon = now;
    phant0m::entropy::mix_hw();
    phant0m::radio::advertise();

    if (phant0m::radio::negotiate_handshake(&g_session)) {
      phant0m::ui::blink(phant0m::LedState::Handshake);
      Serial.println(F("PQC handshake shared secret ready"));
#if PHANT0M_ENABLE_MQTT
      phant0m::mqtt_qkd::publish_session(g_session, solar, ++g_seq);
#endif
    }

#if PHANT0M_ENABLE_TINYML
    phant0m::ApFeature aps[WIFI_SCAN_MAX_APS];
    uint8_t n = 0;
#if PHANT0M_ENABLE_WIFI
    phant0m::tinyml::extract_from_scan(aps, &n, WIFI_SCAN_MAX_APS);
#else
    phant0m::tinyml::ingest_records(aps, &n, g_demo_aps, 2, WIFI_SCAN_MAX_APS);
#endif
    const phant0m::RogueVerdict v = phant0m::tinyml::score(aps, n);
    if (v.flagged) {
      phant0m::ui::set(phant0m::LedState::Rogue);
      Serial.print(F("ROGUE_AP score_q15="));
      Serial.print(v.score_q15);
      Serial.print(F(" ssid="));
      Serial.println(n ? aps[v.ap_index].ssid : "?");
    } else {
      phant0m::ui::set(phant0m::LedState::Idle);
    }
#endif
  }

#if PHANT0M_ENABLE_MQTT
  phant0m::mqtt_qkd::loop();
  phant0m::QkdSyncFrame peer{};
  if (phant0m::mqtt_qkd::poll_peer(&peer)) {
    Serial.print(F("QKD sync peer seq="));
    Serial.print(static_cast<unsigned long>(peer.seq));
    Serial.print(F(" solar_mv="));
    Serial.println(peer.solar_mv);
  }
#endif

#if PHANT0M_MODE_SOLAR
  phant0m::power::light_nap_ms(phant0m::power::next_sleep_ms(solar) / 4);
#else
  delay(50);
#endif
}
