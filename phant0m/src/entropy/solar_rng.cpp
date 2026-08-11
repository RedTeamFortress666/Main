#include "solar_rng.h"
#include <config.h>
#include "../pqc/fips202.h"
#include <Arduino.h>
#include <string.h>
#include <esp_system.h>

namespace phant0m {
namespace entropy {
namespace {

uint8_t pool_[48];
uint32_t counter_ = 0;
uint32_t health_ = 0;
uint16_t last_solar_ = 0;
uint32_t var_acc_ = 0;

uint16_t read_avg(uint8_t pin, int n) {
  uint32_t s = 0;
  for (int i = 0; i < n; ++i) {
    s += analogRead(pin);
    delayMicroseconds(30);
  }
  return static_cast<uint16_t>(s / n);
}

void absorb_words(const uint8_t *in, size_t n) {
  shake::Shake256Inc x;
  x.init();
  x.absorb(pool_, sizeof(pool_));
  x.absorb(in, n);
  x.absorb(reinterpret_cast<const uint8_t *>(&counter_), sizeof(counter_));
  x.finalize();
  x.squeeze(pool_, sizeof(pool_));
  ++counter_;
}

}  // namespace

void begin() {
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  memset(pool_, 0, sizeof(pool_));
  // Seed from ESP32 true RNG (SAR ADC + RF noise in ROM).
  for (int i = 0; i < 12; ++i) {
    const uint32_t w = esp_random();
    memcpy(pool_ + i * 4, &w, 4);
  }
  mix_hw();
}

SolarSample sample() {
  SolarSample s{};
  s.solar_raw = read_avg(PIN_SOLAR_ADC, 4);
  s.ldr_raw = read_avg(PIN_LDR_ADC, 4);
  s.noise_raw = read_avg(PIN_NOISE_ADC, 8);
  // Divider assumed ~2:1 into ADC (0-3.3V). Scale to millivolts of panel.
  s.solar_mv = static_cast<uint16_t>((static_cast<uint32_t>(s.solar_raw) * 3300 * 2) / 4095);
  const int32_t d = static_cast<int32_t>(s.solar_raw) - last_solar_;
  var_acc_ = (var_acc_ * 3 + static_cast<uint32_t>(d * d)) / 4;
  s.variance = var_acc_;
  last_solar_ = s.solar_raw;
  return s;
}

void mix_hw() {
  const SolarSample s = sample();
  uint8_t block[32];
  const uint32_t r0 = esp_random();
  const uint32_t r1 = esp_random();
  const uint32_t t = micros() ^ ESP.getCycleCount();
  memcpy(block + 0, &s.solar_raw, 2);
  memcpy(block + 2, &s.ldr_raw, 2);
  memcpy(block + 4, &s.noise_raw, 2);
  memcpy(block + 6, &s.variance, 4);
  memcpy(block + 10, &r0, 4);
  memcpy(block + 14, &r1, 4);
  memcpy(block + 18, &t, 4);
  // Von Neumann-ish bit from LSB jitter of noise ADC bursts.
  uint8_t vn = 0;
  for (int i = 0; i < 8; ++i) {
    const uint16_t a = analogRead(PIN_NOISE_ADC);
    const uint16_t b = analogRead(PIN_NOISE_ADC);
    vn |= static_cast<uint8_t>(((a ^ b) & 1) << i);
  }
  block[22] = vn;
  block[23] = static_cast<uint8_t>(s.solar_mv);
  absorb_words(block, 24);

  // Health: reward variance + differing LSBs.
  uint32_t h = (var_acc_ > 4 ? 40 : 10) + ((vn != 0) ? 20 : 0) +
               ((s.noise_raw & 0xF) != ((s.noise_raw >> 4) & 0xF) ? 20 : 0);
  health_ = health_ > 200 ? 255 : health_ + h;
}

void randombytes(uint8_t *out, size_t len) {
  if ((counter_ & 0x7) == 0) mix_hw();
  shake::Shake256Inc x;
  x.init();
  x.absorb(pool_, sizeof(pool_));
  x.absorb(reinterpret_cast<const uint8_t *>(&counter_), sizeof(counter_));
  uint32_t r = esp_random();
  x.absorb(reinterpret_cast<uint8_t *>(&r), 4);
  x.finalize();
  x.squeeze(out, len);
  // Forward-secure: re-key pool.
  x.init();
  x.absorb(pool_, sizeof(pool_));
  x.absorb(out, len < 32 ? len : 32);
  x.finalize();
  x.squeeze(pool_, sizeof(pool_));
  ++counter_;
  if (health_ > 0) --health_;
}

uint32_t pool_health() { return health_ > 255 ? 255 : health_; }

}  // namespace entropy
}  // namespace phant0m
