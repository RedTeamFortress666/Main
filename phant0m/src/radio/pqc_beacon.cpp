#include "pqc_beacon.h"
#include <config.h>
#include "../pqc/kyber512.h"
#include "../pqc/fips202.h"
#include "../entropy/solar_rng.h"
#include <Arduino.h>
#include <string.h>

#if PHANT0M_ENABLE_WIFI
#include <WiFi.h>
#endif

#if PHANT0M_ENABLE_BLE
#include <string>
#include <NimBLEDevice.h>
#endif

namespace phant0m {
namespace radio {
namespace {

PqcSession *g_session = nullptr;
char g_ssid[32];
uint8_t g_chunk_idx = 0;

#if PHANT0M_ENABLE_BLE
NimBLEAdvertising *g_adv = nullptr;
#endif

struct __attribute__((packed)) AdvFrame {
  uint8_t magic0;
  uint8_t magic1;
  uint8_t pk_hash[8];
  uint8_t chunk_idx;
  uint8_t chunk[16];
};

constexpr uint8_t ADV_MAGIC0 = 0xF1;
constexpr uint8_t ADV_MAGIC1 = 0x51;

char hexn(uint8_t v) { return "0123456789ABCDEF"[v & 0xF]; }

void append_hex(char *dst, size_t &pos, size_t cap, uint8_t v) {
  if (pos + 2 >= cap) return;
  dst[pos++] = hexn(v >> 4);
  dst[pos++] = hexn(v);
}

void pk_hash8(const uint8_t pk[kyber512::PUBLICKEY_BYTES], uint8_t out[8]) {
  uint8_t h[32];
  shake::sha3_256(h, pk, kyber512::PUBLICKEY_BYTES);
  memcpy(out, h, 8);
}

void fill_frame(AdvFrame &f, uint8_t idx) {
  f.magic0 = ADV_MAGIC0;
  f.magic1 = ADV_MAGIC1;
  pk_hash8(g_session->pk, f.pk_hash);
  f.chunk_idx = idx;
  const size_t off = static_cast<size_t>(idx) * 16;
  if (off + 16 <= kyber512::PUBLICKEY_BYTES) {
    memcpy(f.chunk, g_session->pk + off, 16);
  } else {
    memset(f.chunk, 0, 16);
  }
}

void make_ssid() {
  uint8_t id[3];
  entropy::randombytes(id, sizeof(id));
  // PH0M-XXXXXX
  memcpy(g_ssid, PHANT0M_SSID_PREFIX, 5);
  size_t pos = 5;
  append_hex(g_ssid, pos, sizeof(g_ssid), id[0]);
  append_hex(g_ssid, pos, sizeof(g_ssid), id[1]);
  append_hex(g_ssid, pos, sizeof(g_ssid), id[2]);
  g_ssid[pos] = 0;
}

void make_host(char host[32], const AdvFrame &f) {
  size_t pos = 0;
  host[pos++] = 'p';
  append_hex(host, pos, 32, f.pk_hash[0]);
  append_hex(host, pos, 32, f.pk_hash[1]);
  append_hex(host, pos, 32, f.chunk_idx);
  append_hex(host, pos, 32, f.chunk[0]);
  append_hex(host, pos, 32, f.chunk[1]);
  append_hex(host, pos, 32, f.chunk[2]);
  host[pos] = 0;
}

}  // namespace

void begin(PqcSession *session) {
  g_session = session;
  make_ssid();

#if PHANT0M_ENABLE_WIFI
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(g_ssid, nullptr, PHANT0M_CHANNEL, 0, 2);
  AdvFrame f{};
  fill_frame(f, 0);
  char host[32];
  make_host(host, f);
  WiFi.softAPsetHostname(host);
#elif PHANT0M_ENABLE_BLE
  NimBLEDevice::init(PHANT0M_BLE_NAME);
  NimBLEDevice::setPower(ESP_PWR_LVL_N6);
  g_adv = NimBLEDevice::getAdvertising();
  AdvFrame f{};
  fill_frame(f, 0);
  NimBLEAdvertisementData adv;
  adv.setName(PHANT0M_BLE_NAME);
  adv.setManufacturerData(
      std::string(reinterpret_cast<const char *>(&f), sizeof(f)));
  g_adv->setAdvertisementData(adv);
  g_adv->setMinInterval(0xA0);
  g_adv->setMaxInterval(0xF0);
  g_adv->start();
#else
  Serial.print(F("BEACON "));
  Serial.println(g_ssid);
#endif
}

void advertise() {
  if (!g_session || !g_session->has_keys) return;
  g_chunk_idx =
      static_cast<uint8_t>((g_chunk_idx + 1) % (kyber512::PUBLICKEY_BYTES / 16));
  AdvFrame f{};
  fill_frame(f, g_chunk_idx);

#if PHANT0M_ENABLE_WIFI
  char host[32];
  make_host(host, f);
  WiFi.softAPsetHostname(host);
#elif PHANT0M_ENABLE_BLE
  if (g_adv) {
    NimBLEAdvertisementData adv;
    adv.setName(PHANT0M_BLE_NAME);
    adv.setManufacturerData(
        std::string(reinterpret_cast<const char *>(&f), sizeof(f)));
    g_adv->stop();
    g_adv->setAdvertisementData(adv);
    g_adv->start();
  }
#else
  Serial.write(0xB0);
  Serial.write(0xEA);
  Serial.write(reinterpret_cast<const uint8_t *>(&f), sizeof(f));
#endif
}

bool negotiate_handshake(PqcSession *session) {
  if (!session || !session->has_keys) return false;

#if PHANT0M_ENABLE_WIFI
  const int n = WiFi.scanNetworks(false, true);
  for (int i = 0; i < n; ++i) {
    const String ssid = WiFi.SSID(i);
    if (ssid.startsWith(PHANT0M_SSID_PREFIX) && ssid != String(g_ssid)) break;
  }
  WiFi.scanDelete();
#endif

  if (!session->has_shared) {
    if (kyber512::encaps(session->ct, session->ss, session->pk) == 0) {
      session->has_shared = true;
      return true;
    }
  }
  return session->has_shared;
}

void stop() {
#if PHANT0M_ENABLE_WIFI
  WiFi.softAPdisconnect(true);
  WiFi.mode(WIFI_OFF);
#endif
#if PHANT0M_ENABLE_BLE
  if (g_adv) g_adv->stop();
  NimBLEDevice::deinit(true);
#endif
}

}  // namespace radio
}  // namespace phant0m
