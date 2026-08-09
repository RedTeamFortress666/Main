#pragma once

#include <Arduino.h>

#if defined(BOARD_TDECK)
  #define POLY_BOARD_NAME "T-Deck"
  #define POLY_POWER_ON_PIN 10
  #define POLY_I2C_SDA 18
  #define POLY_I2C_SCL 8
  #define POLY_KB_INT 46
  #define POLY_KB_ADDR 0x55
  #define POLY_HAS_KEYBOARD 1
  #define POLY_TFT_ROTATION 1
#elif defined(BOARD_TEMBED)
  #define POLY_BOARD_NAME "T-Embed"
  #define POLY_POWER_ON_PIN 46
  #define POLY_ENC_A 2
  #define POLY_ENC_B 1
  #define POLY_ENC_BTN 0
  #define POLY_HAS_ENCODER 1
  #define POLY_TFT_ROTATION 3
#elif defined(BOARD_CYD)
  #define POLY_BOARD_NAME "CYD"
  #define POLY_HAS_TOUCH 1
  #define POLY_TFT_ROTATION 1
  #define POLY_TOUCH_IRQ 36
  #define POLY_TOUCH_MOSI 32
  #define POLY_TOUCH_MISO 39
  #define POLY_TOUCH_CLK 25
  #define POLY_TOUCH_CS 33
#elif defined(BOARD_CARDPUTER)
  #define POLY_BOARD_NAME "Cardputer"
  #define POLY_HAS_CARDPUTER_KB 1
  #define POLY_TFT_ROTATION 1
#else
  #define POLY_BOARD_NAME "UNKNOWN"
  #define POLY_TFT_ROTATION 1
#endif
