#pragma once

#include <phant0m_types.h>
#include <stdint.h>

namespace phant0m {
namespace power {

void begin();
void apply_solar_profile(const SolarSample &s);
uint32_t next_sleep_ms(const SolarSample &s);
void deep_sleep_ms(uint32_t ms);
void light_nap_ms(uint32_t ms);
bool critically_low(const SolarSample &s);

}  // namespace power
}  // namespace phant0m
