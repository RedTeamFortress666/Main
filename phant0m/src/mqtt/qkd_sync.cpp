#include "qkd_sync.h"
#include <config.h>
#include "../pqc/fips202.h"
#include <Arduino.h>
#include <string.h>

#if PHANT0M_ENABLE_MQTT && PHANT0M_ENABLE_WIFI
#include <WiFi.h>
#include <PubSubClient.h>
#endif

namespace phant0m {
namespace mqtt_qkd {
namespace {

QkdSyncFrame g_last{};
bool g_have_peer = false;

#if PHANT0M_ENABLE_MQTT && PHANT0M_ENABLE_WIFI
WiFiClient g_net;
PubSubClient g_mqtt(g_net);

void on_message(char *topic, byte *payload, unsigned int len) {
  (void)topic;
  if (len < sizeof(QkdSyncFrame)) return;
  memcpy(&g_last, payload, sizeof(QkdSyncFrame));
  g_have_peer = true;
}

bool ensure_wifi_sta() {
  if (WiFi.status() == WL_CONNECTED) return true;
#ifdef PHANT0M_STA_SSID
  WiFi.begin(PHANT0M_STA_SSID, PHANT0M_STA_PASS);
  const uint32_t start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 4000) delay(100);
#endif
  return WiFi.status() == WL_CONNECTED;
}
#endif

void build_frame(QkdSyncFrame &frame, const PqcSession &session,
                 const SolarSample &solar, uint32_t seq) {
  shake::shake256(frame.key_id, sizeof(frame.key_id), session.ss,
                  sizeof(session.ss));
  memcpy(frame.ss, session.ss, sizeof(frame.ss));
  frame.seq = seq;
  frame.solar_mv = solar.solar_mv;
  frame.flags = (solar.solar_mv < SOLAR_MV_LOW) ? 0x01 : 0x00;
}

}  // namespace

void begin() {
#if PHANT0M_ENABLE_MQTT && PHANT0M_ENABLE_WIFI
  g_mqtt.setServer(PHANT0M_MQTT_HOST, PHANT0M_MQTT_PORT);
  g_mqtt.setCallback(on_message);
  g_mqtt.setBufferSize(128);
#endif
}

bool connected() {
#if PHANT0M_ENABLE_MQTT && PHANT0M_ENABLE_WIFI
  return g_mqtt.connected();
#elif PHANT0M_ENABLE_MQTT
  return true;
#else
  return false;
#endif
}

void loop() {
#if PHANT0M_ENABLE_MQTT && PHANT0M_ENABLE_WIFI
  if (!ensure_wifi_sta()) return;
  if (!g_mqtt.connected()) {
    if (g_mqtt.connect(PHANT0M_MQTT_CLIENT_ID)) {
      g_mqtt.subscribe(PHANT0M_MQTT_TOPIC_SUB);
    }
  }
  g_mqtt.loop();
#elif PHANT0M_ENABLE_MQTT
  if (Serial.available() >= static_cast<int>(sizeof(QkdSyncFrame) + 2)) {
    if (Serial.read() == 0xA5 && Serial.read() == 0x5A) {
      Serial.readBytes(reinterpret_cast<char *>(&g_last), sizeof(g_last));
      g_have_peer = true;
    }
  }
#endif
}

bool publish_session(const PqcSession &session, const SolarSample &solar,
                     uint32_t seq) {
#if !PHANT0M_ENABLE_MQTT
  (void)session;
  (void)solar;
  (void)seq;
  return false;
#else
  if (!session.has_shared) return false;
  QkdSyncFrame frame{};
  build_frame(frame, session, solar, seq);
#if PHANT0M_ENABLE_WIFI
  loop();
  if (!g_mqtt.connected()) return false;
  return g_mqtt.publish(PHANT0M_MQTT_TOPIC_PUB,
                        reinterpret_cast<const uint8_t *>(&frame),
                        sizeof(frame), false);
#else
  Serial.write(0xA5);
  Serial.write(0x5A);
  Serial.write(reinterpret_cast<const uint8_t *>(&frame), sizeof(frame));
  return true;
#endif
#endif
}

bool poll_peer(QkdSyncFrame *out) {
  if (!g_have_peer || !out) return false;
  *out = g_last;
  g_have_peer = false;
  return true;
}

}  // namespace mqtt_qkd
}  // namespace phant0m
