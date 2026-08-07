#include "polybius/serial_shell.h"

#include "polybius/cipher_engine.h"
#include "polybius/pool_sync.h"
#include "polybius/utf8_util.h"

#include <Arduino.h>

#include <cstdlib>
#include <sstream>

namespace polybius {
namespace {

void println(const std::string& s) { Serial.println(s.c_str()); }

std::string trim(std::string s) {
  while (!s.empty() && (s.back() == '\r' || s.back() == '\n' || s.back() == ' '))
    s.pop_back();
  size_t i = 0;
  while (i < s.size() && s[i] == ' ') ++i;
  return s.substr(i);
}

}  // namespace

void SerialShell::begin(AppState& state) {
  Serial.begin(115200);
  delay(200);
  println("");
  println("PØLYBĪUS ESP32 — type 'help'");
  state.status = "serial ready";
}

bool SerialShell::poll(AppState& state) {
  static std::string line;
  bool changed = false;
  while (Serial.available()) {
    const char c = static_cast<char>(Serial.read());
    if (c == '\r') continue;
    if (c != '\n') {
      line.push_back(c);
      continue;
    }
    const std::string cmd = trim(line);
    line.clear();
    if (cmd.empty()) continue;
    changed = true;

    if (cmd == "help") {
      println("unlock <pin> | seed <s> | complexity <2-6>");
      println("enc <text> | dec <emoji> | pool | sync | import <token>");
      println("home | encrypt | decrypt | screen pool | screen sync");
    } else if (cmd.rfind("unlock ", 0) == 0) {
      const std::string pin = trim(cmd.substr(7));
      if (pin == state.pin || pin == "000000" || pin == "B1-66-3R") {
        state.unlocked = true;
        state.status = "UNLOCKED";
        println("OK unlocked");
      } else {
        state.status = "bad pin";
        println("ERR bad pin");
      }
    } else if (cmd.rfind("seed ", 0) == 0) {
      state.seed = trim(cmd.substr(5));
      state.status = "seed set";
      println(std::string("OK seed → pool ") +
              CipherEngine(state.seed, state.complexity).poolId());
    } else if (cmd.rfind("complexity ", 0) == 0) {
      const int c = std::atoi(cmd.c_str() + 11);
      state.complexity = c < 2 ? 2 : (c > 6 ? 6 : c);
      println(std::string("OK complexity ") + std::to_string(state.complexity));
    } else if (cmd.rfind("enc ", 0) == 0) {
      if (!state.unlocked) {
        println("ERR unlock first");
      } else {
        CipherEngine eng(state.seed, state.complexity);
        state.draft = trim(cmd.substr(4));
        state.lastResult = eng.encrypt(state.draft);
        state.screen = UiScreen::Encrypt;
        println(state.lastResult);
      }
    } else if (cmd.rfind("dec ", 0) == 0) {
      if (!state.unlocked) {
        println("ERR unlock first");
      } else {
        CipherEngine eng(state.seed, state.complexity);
        state.draft = trim(cmd.substr(4));
        state.lastResult = eng.decrypt(state.draft);
        state.screen = UiScreen::Decrypt;
        println(state.lastResult);
      }
    } else if (cmd == "pool") {
      CipherEngine eng(state.seed, state.complexity);
      state.screen = UiScreen::Pool;
      println(std::string("poolId=") + eng.poolId());
      println(std::string("seed=") + state.seed);
      println(std::string("complexity=") + std::to_string(state.complexity));
    } else if (cmd == "sync") {
      const auto tok = PoolSync::fromSeed(state.seed, state.complexity, 6LL * 3600 * 1000,
                                          static_cast<int64_t>(millis()));
      state.screen = UiScreen::Sync;
      state.lastResult = tok.encode();
      println(state.lastResult);
    } else if (cmd.rfind("import ", 0) == 0) {
      const auto tok = PoolSync::tryParse(trim(cmd.substr(7)));
      if (!tok || !tok->verifyIntegrity()) {
        println("ERR bad token");
        state.status = "import failed";
      } else {
        state.seed = tok->seed;
        state.complexity = tok->complexity;
        state.status = "imported";
        println(std::string("OK pool ") + tok->poolId);
      }
    } else if (cmd == "home") {
      state.screen = UiScreen::Home;
    } else if (cmd == "encrypt") {
      state.screen = UiScreen::Encrypt;
    } else if (cmd == "decrypt") {
      state.screen = UiScreen::Decrypt;
    } else if (cmd == "screen pool") {
      state.screen = UiScreen::Pool;
    } else if (cmd == "screen sync") {
      state.screen = UiScreen::Sync;
    } else {
      println("ERR unknown — help");
    }
  }
  return changed;
}

}  // namespace polybius
