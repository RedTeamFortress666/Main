#pragma once

#include <string>

namespace polybius {

enum class UiScreen {
  Home,
  Encrypt,
  Decrypt,
  Pool,
  Sync,
  Help,
};

struct AppState {
  std::string seed = "2026-07-22";
  int complexity = 2;
  bool unlocked = false;
  std::string pin = "000000";
  std::string draft;       // plaintext or ciphertext being edited
  std::string lastResult;  // last encrypt/decrypt output
  std::string status;
  UiScreen screen = UiScreen::Home;
};

class BoardUi {
 public:
  virtual ~BoardUi() = default;
  virtual void begin() = 0;
  virtual void draw(const AppState& state) = 0;
  /// Poll input; may mutate state. Return true if state changed.
  virtual bool poll(AppState& state) = 0;
};

BoardUi* createBoardUi();

}  // namespace polybius
