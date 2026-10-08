#pragma once

#include <phant0m_types.h>
#include <stdint.h>
#include <stddef.h>

namespace phant0m {
namespace radio {

void begin(PqcSession *session);
// Advertise PK fragment over WiFi beacon/IE payload or BLE adv manufacturer data.
void advertise();
// Scan for peer Phant0m beacons and complete Kyber encaps if PK found.
bool negotiate_handshake(PqcSession *session);
void stop();

}  // namespace radio
}  // namespace phant0m
