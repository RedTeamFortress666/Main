#include "polybius/board_ui.h"

#include "boards/board_pins.h"
#include "polybius/cipher_engine.h"

#include <TFT_eSPI.h>
#include <Wire.h>

#if defined(POLY_HAS_TOUCH)
#include <SPI.h>
#include <XPT2046_Touchscreen.h>
#endif

namespace polybius {
namespace {

TFT_eSPI tft;

#if defined(POLY_HAS_TOUCH)
SPIClass touchSpi = SPIClass(VSPI);
XPT2046_Touchscreen touch(POLY_TOUCH_CS, POLY_TOUCH_IRQ);
#endif

#if defined(POLY_HAS_ENCODER)
volatile int encDelta = 0;
int lastEnc = 0;
void IRAM_ATTR onEncA() {
  const int a = digitalRead(POLY_ENC_A);
  const int b = digitalRead(POLY_ENC_B);
  encDelta += (a == b) ? 1 : -1;
}
#endif

const char* screenName(UiScreen s) {
  switch (s) {
    case UiScreen::Home: return "HOME";
    case UiScreen::Encrypt: return "ENCRYPT";
    case UiScreen::Decrypt: return "DECRYPT";
    case UiScreen::Pool: return "POOL";
    case UiScreen::Sync: return "SYNC";
    case UiScreen::Help: return "HELP";
  }
  return "?";
}

class TftBoardUi : public BoardUi {
 public:
  void begin() override {
#if defined(POLY_POWER_ON_PIN)
    pinMode(POLY_POWER_ON_PIN, OUTPUT);
    digitalWrite(POLY_POWER_ON_PIN, HIGH);
    delay(50);
#endif
    tft.init();
    tft.setRotation(POLY_TFT_ROTATION);
    tft.fillScreen(TFT_BLACK);
    tft.setTextDatum(TL_DATUM);
    tft.setTextColor(TFT_GREENYELLOW, TFT_BLACK);

#if defined(POLY_HAS_KEYBOARD)
    Wire.begin(POLY_I2C_SDA, POLY_I2C_SCL);
    pinMode(POLY_KB_INT, INPUT_PULLUP);
#endif

#if defined(POLY_HAS_ENCODER)
    pinMode(POLY_ENC_A, INPUT_PULLUP);
    pinMode(POLY_ENC_B, INPUT_PULLUP);
    pinMode(POLY_ENC_BTN, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(POLY_ENC_A), onEncA, CHANGE);
#endif

#if defined(POLY_HAS_TOUCH)
    touchSpi.begin(POLY_TOUCH_CLK, POLY_TOUCH_MISO, POLY_TOUCH_MOSI, POLY_TOUCH_CS);
    touch.begin(touchSpi);
    touch.setRotation(POLY_TFT_ROTATION);
#endif

    tft.setTextSize(2);
    tft.drawString("POLYBIUS", 8, 8);
    tft.setTextSize(1);
    tft.drawString(POLY_BOARD_NAME, 8, 32);
    tft.drawString("serial: help", 8, 48);
  }

  void draw(const AppState& state) override {
    tft.fillScreen(TFT_BLACK);
    tft.setTextColor(TFT_MAGENTA, TFT_BLACK);
    tft.setTextSize(2);
    tft.drawString("POLYBIUS", 8, 6);
    tft.setTextSize(1);
    tft.setTextColor(TFT_DARKGREY, TFT_BLACK);
    tft.drawString(POLY_BOARD_NAME, 8, 28);

    tft.setTextColor(TFT_CYAN, TFT_BLACK);
    tft.drawString(screenName(state.screen), 8, 44);

    tft.setTextColor(state.unlocked ? TFT_GREEN : TFT_RED, TFT_BLACK);
    tft.drawString(state.unlocked ? "UNLOCKED" : "LOCKED", 8, 60);

    CipherEngine eng(state.seed, state.complexity);
    tft.setTextColor(TFT_YELLOW, TFT_BLACK);
    tft.drawString((std::string("pool ") + eng.poolId()).c_str(), 8, 76);
    tft.setTextColor(TFT_DARKGREY, TFT_BLACK);
    tft.drawString((std::string("c=") + std::to_string(state.complexity)).c_str(),
                   8, 92);

    tft.setTextColor(TFT_WHITE, TFT_BLACK);
    const std::string body =
        state.lastResult.empty() ? state.status : state.lastResult;
    // Wrap roughly — TFT_eSPI has no built-in wrap for UTF-8 emoji; show ASCII-ish.
    int y = 112;
    std::string line;
    for (size_t i = 0; i < body.size() && y < tft.height() - 20; ++i) {
      line.push_back(body[i]);
      if (line.size() >= 36 || body[i] == '\n') {
        tft.drawString(line.c_str(), 8, y);
        y += 12;
        line.clear();
      }
    }
    if (!line.empty() && y < tft.height() - 10) tft.drawString(line.c_str(), 8, y);

    tft.setTextColor(TFT_DARKGREY, TFT_BLACK);
#if defined(POLY_HAS_KEYBOARD)
    tft.drawString("keys: type | trackball: unused", 8, tft.height() - 12);
#elif defined(POLY_HAS_ENCODER)
    tft.drawString("dial: screen  click: cycle", 8, tft.height() - 12);
#elif defined(POLY_HAS_TOUCH)
    tft.drawString("tap bottom: next screen", 8, tft.height() - 12);
#else
    tft.drawString("use USB serial", 8, tft.height() - 12);
#endif
  }

  bool poll(AppState& state) override {
    bool changed = false;

#if defined(POLY_HAS_KEYBOARD)
    if (digitalRead(POLY_KB_INT) == LOW) {
      Wire.requestFrom(static_cast<uint8_t>(POLY_KB_ADDR), static_cast<uint8_t>(1));
      if (Wire.available()) {
        const char key = static_cast<char>(Wire.read());
        if (key == '\n' || key == '\r') {
          if (state.unlocked && state.screen == UiScreen::Encrypt) {
            CipherEngine eng(state.seed, state.complexity);
            state.lastResult = eng.encrypt(state.draft);
            changed = true;
          } else if (state.unlocked && state.screen == UiScreen::Decrypt) {
            CipherEngine eng(state.seed, state.complexity);
            state.lastResult = eng.decrypt(state.draft);
            changed = true;
          }
        } else if (key == 0x08 || key == 0x7F) {
          if (!state.draft.empty()) {
            state.draft.pop_back();
            changed = true;
          }
        } else if (key >= 32 && key < 127) {
          state.draft.push_back(key);
          changed = true;
        }
      }
    }
#endif

#if defined(POLY_HAS_ENCODER)
    noInterrupts();
    const int d = encDelta;
    encDelta = 0;
    interrupts();
    if (d != 0) {
      int idx = static_cast<int>(state.screen);
      idx = (idx + (d > 0 ? 1 : -1) + 5) % 5;
      state.screen = static_cast<UiScreen>(idx);
      changed = true;
    }
    static bool prevBtn = true;
    const bool btn = digitalRead(POLY_ENC_BTN);
    if (prevBtn && !btn) {
      state.screen = static_cast<UiScreen>(
          (static_cast<int>(state.screen) + 1) % 5);
      changed = true;
    }
    prevBtn = btn;
#endif

#if defined(POLY_HAS_TOUCH)
    if (touch.tirqTouched() && touch.touched()) {
      const TS_Point p = touch.getPoint();
      // Rough: bottom third cycles screens.
      if (p.y > 3000) {
        state.screen = static_cast<UiScreen>(
            (static_cast<int>(state.screen) + 1) % 5);
        changed = true;
        delay(250);
      }
    }
#endif
    return changed;
  }
};

}  // namespace

BoardUi* createBoardUi() { return new TftBoardUi(); }

}  // namespace polybius
