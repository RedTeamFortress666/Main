#pragma once

#include <phant0m_types.h>
#include <stdint.h>

namespace phant0m {
namespace mqtt_qkd {

// Lightweight MQTT client for field "QKD-style" PQC key sync.
// Publishes shared-secret key IDs + solar telemetry; pulls peer key material.
void begin();
bool connected();
void loop();
bool publish_session(const PqcSession &session, const SolarSample &solar, uint32_t seq);
bool poll_peer(QkdSyncFrame *out);

}  // namespace mqtt_qkd
}  // namespace phant0m
