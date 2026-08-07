#pragma once

#include <Arduino.h>
#include <vector>

namespace polybius {

/// Minimal M5Stack Cardputer (original) 74HC138 matrix keyboard reader.
class CardputerKeyboard {
 public:
  void begin();
  /// Poll matrix; returns newly pressed printable/control chars this tick.
  std::vector<char> pollChars();

 private:
  static constexpr int kOutPins[3] = {8, 9, 11};
  static constexpr int kInPins[7] = {13, 15, 3, 4, 5, 6, 7};

  struct Chart {
    uint8_t x1;
    uint8_t x2;
  };
  static constexpr Chart kXMap[7] = {
      {0, 1}, {2, 3}, {4, 5}, {6, 7}, {8, 9}, {10, 11}, {12, 13}};

  void setOutput(uint8_t output);
  uint8_t getInput();

  uint64_t prevMask_ = 0;
};

}  // namespace polybius
