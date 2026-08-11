#include "solar_pm.h"
#include <config.h>
#include <Arduino.h>
#include <esp_sleep.h>

namespace phant0m {
namespace power {

void begin() {
#if PHANT0M_MODE_SOLAR
  setCpuFrequencyMhz(CPU_MHZ_SOLAR);
#endif
  pinMode(PIN_TFT_BL, OUTPUT);
#if !PHANT0M_ENABLE_DISPLAY
  digitalWrite(PIN_TFT_BL, LOW);  // backlight off saves ~40-80 mA
#endif
  pinMode(PIN_LED_R, OUTPUT);
  pinMode(PIN_LED_G, OUTPUT);
  pinMode(PIN_LED_B, OUTPUT);
  digitalWrite(PIN_LED_R, HIGH);
  digitalWrite(PIN_LED_G, HIGH);
  digitalWrite(PIN_LED_B, HIGH);
}

void apply_solar_profile(const SolarSample &s) {
#if PHANT0M_MODE_SOLAR
  if (s.solar_mv < SOLAR_MV_CRIT) {
    setCpuFrequencyMhz(80);
  } else if (s.solar_mv < SOLAR_MV_LOW) {
    setCpuFrequencyMhz(80);
  } else {
    setCpuFrequencyMhz(160);
  }
#else
  (void)s;
#endif
}

uint32_t next_sleep_ms(const SolarSample &s) {
  if (s.solar_mv < SOLAR_MV_CRIT) return SLEEP_MS_CRIT;
  if (s.solar_mv < SOLAR_MV_LOW) return SLEEP_MS_LOW;
  return SLEEP_MS_FULL;
}

bool critically_low(const SolarSample &s) { return s.solar_mv < SOLAR_MV_CRIT; }

void light_nap_ms(uint32_t ms) {
  delay(ms);  // keep RAM; WiFi modem can stay up briefly
}

void deep_sleep_ms(uint32_t ms) {
  esp_sleep_enable_timer_wakeup(static_cast<uint64_t>(ms) * 1000ULL);
  esp_deep_sleep_start();
}

}  // namespace power
}  // namespace phant0m
