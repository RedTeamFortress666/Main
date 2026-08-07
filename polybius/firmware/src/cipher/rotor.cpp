#include "polybius/rotor.h"

#include "polybius/dart_compat.h"
#include "polybius/sha256.h"

#include <numeric>

namespace polybius {

Rotor::Rotor(std::string name, std::vector<int> wiring, int notch)
    : name_(std::move(name)), wiring_(std::move(wiring)), notch_(notch) {}

Rotor Rotor::create(const std::string& name, const std::string& dateKey, int offset) {
  const std::string key = dateKey + "::" + name + "::" + std::to_string(offset);
  const auto dig = sha256Utf16CodeUnits(key);
  int fold = 0;
  for (uint8_t b : dig) fold ^= static_cast<int>(b);
  DartRandom rng(fold);

  std::vector<int> wiring(kAlphabetSize);
  std::iota(wiring.begin(), wiring.end(), 0);
  for (int i = kAlphabetSize; i > 1; --i) {
    const int j = rng.nextInt(i);
    std::swap(wiring[i - 1], wiring[j]);
  }
  const int notch = rng.nextInt(kAlphabetSize);
  return Rotor(name, std::move(wiring), notch);
}

void Rotor::step() {
  position_ = (position_ + 1) % kAlphabetSize;
  ++stepCount_;
}

int Rotor::forward(int input) const {
  const int shifted = (input + position_) % kAlphabetSize;
  return wiring_[shifted];
}

int Rotor::backward(int input) const {
  int index = -1;
  for (int i = 0; i < kAlphabetSize; ++i) {
    if (wiring_[i] == input) {
      index = i;
      break;
    }
  }
  if (index < 0) return 0;
  return (index - position_ + kAlphabetSize) % kAlphabetSize;
}

}  // namespace polybius
