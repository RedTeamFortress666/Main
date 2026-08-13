#include "polybius/cardputer_kb.h"

#if defined(BOARD_CARDPUTER)

namespace polybius {
namespace {

// Special key codes matching M5Cardputer Keyboard_def.h (value_first column).
constexpr char kKeyBackspace = static_cast<char>(0x2a);
constexpr char kKeyEnter = static_cast<char>(0x28);
constexpr char kKeyTab = static_cast<char>(0x2b);
constexpr char kKeyFn = static_cast<char>(0xff);
constexpr char kKeyShift = static_cast<char>(0x81);
constexpr char kKeyCtrl = static_cast<char>(0x80);
constexpr char kKeyAlt = static_cast<char>(0x82);
constexpr char kKeyOpt = static_cast<char>(0x00);

struct KeyCell {
  char normal;
  char shifted;
};

// 4 rows × 14 cols — matches M5Cardputer `_key_value_map`.
const KeyCell kMap[4][14] = {
    {{'`', '~'},  {'1', '!'}, {'2', '@'}, {'3', '#'}, {'4', '$'},
     {'5', '%'},  {'6', '^'}, {'7', '&'}, {'8', '*'}, {'9', '('},
     {'0', ')'},  {'-', '_'}, {'=', '+'}, {kKeyBackspace, kKeyBackspace}},
    {{kKeyTab, kKeyTab},
     {'q', 'Q'}, {'w', 'W'}, {'e', 'E'}, {'r', 'R'}, {'t', 'T'},
     {'y', 'Y'}, {'u', 'U'}, {'i', 'I'}, {'o', 'O'}, {'p', 'P'},
     {'[', '{'}, {']', '}'}, {'\\', '|'}},
    {{kKeyFn, kKeyFn},
     {kKeyShift, kKeyShift},
     {'a', 'A'}, {'s', 'S'}, {'d', 'D'}, {'f', 'F'}, {'g', 'G'},
     {'h', 'H'}, {'j', 'J'}, {'k', 'K'}, {'l', 'L'}, {';', ':'},
     {'\'', '"'}, {kKeyEnter, kKeyEnter}},
    {{kKeyCtrl, kKeyCtrl},
     {kKeyOpt, kKeyOpt},
     {kKeyAlt, kKeyAlt},
     {'z', 'Z'}, {'x', 'X'}, {'c', 'C'}, {'v', 'V'}, {'b', 'B'},
     {'n', 'N'}, {'m', 'M'}, {',', '<'}, {'.', '>'}, {'/', '?'},
     {' ', ' '}},
};

}  // namespace

void CardputerKeyboard::setOutput(uint8_t output) {
  output &= 0x07;
  digitalWrite(kOutPins[0], (output & 0x01) ? HIGH : LOW);
  digitalWrite(kOutPins[1], (output & 0x02) ? HIGH : LOW);
  digitalWrite(kOutPins[2], (output & 0x04) ? HIGH : LOW);
}

uint8_t CardputerKeyboard::getInput() {
  uint8_t buffer = 0;
  for (int i = 0; i < 7; ++i) {
    if (digitalRead(kInPins[i]) == LOW) buffer |= static_cast<uint8_t>(1u << i);
  }
  return buffer;
}

void CardputerKeyboard::begin() {
  for (int pin : kOutPins) {
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
  }
  for (int pin : kInPins) {
    pinMode(pin, INPUT_PULLUP);
  }
  setOutput(0);
}

std::vector<char> CardputerKeyboard::pollChars() {
  std::vector<char> out;
  uint64_t mask = 0;
  bool shift = false;
  struct Hit {
    int x;
    int y;
  };
  Hit hits[32];
  int nHits = 0;

  for (int i = 0; i < 8; ++i) {
    setOutput(static_cast<uint8_t>(i));
    delayMicroseconds(20);
    const uint8_t input = getInput();
    if (!input) continue;
    for (int j = 0; j < 7; ++j) {
      if (!(input & (1u << j))) continue;
      int x = (i > 3) ? kXMap[j].x1 : kXMap[j].x2;
      int y = (i > 3) ? (i - 4) : i;
      y = -y + 3;
      if (x < 0 || x > 13 || y < 0 || y > 3) continue;
      const int bit = y * 14 + x;
      mask |= (1ull << bit);
      if (nHits < 32) hits[nHits++] = {x, y};
      if (kMap[y][x].normal == kKeyShift) shift = true;
    }
  }

  const uint64_t newly = mask & ~prevMask_;
  prevMask_ = mask;
  if (!newly) return out;

  for (int i = 0; i < nHits; ++i) {
    const int bit = hits[i].y * 14 + hits[i].x;
    if (!(newly & (1ull << bit))) continue;
    const char raw =
        shift ? kMap[hits[i].y][hits[i].x].shifted
              : kMap[hits[i].y][hits[i].x].normal;
    if (raw == kKeyShift || raw == kKeyFn || raw == kKeyCtrl ||
        raw == kKeyAlt || raw == kKeyOpt || raw == kKeyTab) {
      continue;
    }
    if (raw == kKeyBackspace) {
      out.push_back(0x08);
    } else if (raw == kKeyEnter) {
      out.push_back('\n');
    } else if (raw >= 32 && raw < 127) {
      out.push_back(raw);
    }
  }
  return out;
}

}  // namespace polybius

#endif  // BOARD_CARDPUTER
