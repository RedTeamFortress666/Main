#include "status_led.h"
#include <config.h>
#include <Arduino.h>

namespace phant0m {
namespace ui {
namespace {

void rgb(bool r, bool g, bool b) {
  // Active LOW on CYD
  digitalWrite(PIN_LED_R, r ? LOW : HIGH);
  digitalWrite(PIN_LED_G, g ? LOW : HIGH);
  digitalWrite(PIN_LED_B, b ? LOW : HIGH);
}

}  // namespace

void begin() {
  pinMode(PIN_LED_R, OUTPUT);
  pinMode(PIN_LED_G, OUTPUT);
  pinMode(PIN_LED_B, OUTPUT);
  rgb(false, false, false);
}

void set(LedState st) {
  switch (st) {
    case LedState::Idle:
      rgb(false, true, false);
      break;
    case LedState::Handshake:
      rgb(false, false, true);
      break;
    case LedState::Rogue:
      rgb(true, false, false);
      break;
    case LedState::LowPower:
      rgb(true, true, false);
      break;
    case LedState::Error:
      rgb(true, false, true);
      break;
    default:
      rgb(false, false, false);
      break;
  }
}

void blink(LedState st) {
  set(st);
  delay(40);
  set(LedState::Off);
}

}  // namespace ui
}  // namespace phant0m
