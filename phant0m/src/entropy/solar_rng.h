#pragma once

#include <phant0m_types.h>
#include <stdint.h>
#include <stddef.h>

namespace phant0m {
namespace entropy {

void begin();
SolarSample sample();
void mix_hw();                 // fold ESP32 HW RNG + ADC variance into pool
void randombytes(uint8_t *out, size_t len);
uint32_t pool_health();        // entropy estimate (0-255)

}  // namespace entropy
}  // namespace phant0m
