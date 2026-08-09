#include "polybius/cipher_engine.h"

#include "polybius/daily_pool.h"
#include "polybius/dart_compat.h"
#include "polybius/rotor.h"
#include "polybius/sha256.h"
#include "polybius/utf8_util.h"

#include <algorithm>
#include <cctype>
#include <cstdint>

namespace polybius {

int CipherEngine::RotorState::forward(int input) const {
  const int shifted = (input + position) % Rotor::kAlphabetSize;
  return wiring[shifted];
}

int CipherEngine::RotorState::backward(int input) const {
  int index = -1;
  for (int i = 0; i < Rotor::kAlphabetSize; ++i) {
    if (wiring[i] == input) {
      index = i;
      break;
    }
  }
  if (index < 0) return 0;
  return (index - position + Rotor::kAlphabetSize) % Rotor::kAlphabetSize;
}

void CipherEngine::RotorState::step() {
  position = (position + 1) % Rotor::kAlphabetSize;
}

std::vector<int> CipherEngine::buildReflector(const std::string& dateKey) {
  std::vector<int> wiring(Rotor::kAlphabetSize);
  for (int i = 0; i < Rotor::kAlphabetSize; ++i) wiring[i] = i;
  // Unsigned LCG — signed overflow is UB and miscompiles at -O1/-O2.
  uint32_t seed = dartStringHash(dateKey);
  for (int i = Rotor::kAlphabetSize - 1; i > 0; --i) {
    seed = (seed * 1103515245u + 12345u) & 0x7fffffffu;
    const int j = static_cast<int>(seed % static_cast<uint32_t>(i + 1));
    std::swap(wiring[i], wiring[j]);
  }
  for (int i = 0; i < Rotor::kAlphabetSize; ++i) {
    if (wiring[wiring[i]] != i) {
      wiring[wiring[i]] = i;
    }
  }
  return wiring;
}

int CipherEngine::charsetIndex(char c) {
  const std::string cs = kCharset;
  const auto pos = cs.find(c);
  return pos == std::string::npos ? -1 : static_cast<int>(pos);
}

CipherEngine::CipherEngine(std::string seed, int complexity)
    : seed_(std::move(seed)),
      complexity_(complexity < 2 ? 2 : (complexity > 6 ? 6 : complexity)) {
  pool_ = DailyPool::generate(seed_);
  reflector_ = buildReflector(seed_);
  resetRotors();
}

std::string CipherEngine::poolId() const {
  auto hex = sha256Hex(seed_);
  std::transform(hex.begin(), hex.end(), hex.begin(),
                 [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
  return hex.substr(0, 12);
}

void CipherEngine::resetRotors() {
  auto load = [&](const char* name, int offset) {
    Rotor r = Rotor::create(name, seed_, offset);
    RotorState s;
    s.wiring = r.wiring();
    s.notch = r.notch();
    s.position = 0;
    return s;
  };
  rI_ = load("I", 0);
  rII_ = load("II", 1);
  rIII_ = load("III", 2);
}

void CipherEngine::stepRotors() {
  if (rIII_.atNotch()) rII_.step();
  if (rII_.atNotch()) rI_.step();
  rIII_.step();
  rII_.step();
  rI_.step();
}

int CipherEngine::transform(int input) {
  int signal = rI_.forward(input);
  signal = rII_.forward(signal);
  signal = rIII_.forward(signal);
  signal = reflector_[signal % static_cast<int>(reflector_.size())];
  signal = rIII_.backward(signal);
  signal = rII_.backward(signal);
  signal = rI_.backward(signal);
  return signal % Rotor::kAlphabetSize;
}

std::string CipherEngine::toEmojiPair(int charIndex, int transformed) const {
  const int idx1 = transformed % kHalfPool;
  const int idx2 = charIndex % kHalfPool;
  std::string out;
  appendUtf8(out, pool_[idx1]);
  appendUtf8(out, pool_[idx2 + kHalfPool]);
  return out;
}

bool CipherEngine::fromEmojiPair(uint32_t e1, uint32_t e2, int& transformed,
                                 int& charIndex) const {
  int idx1 = -1;
  int idx2 = -1;
  for (int i = 0; i < kPoolSize; ++i) {
    if (pool_[i] == e1) idx1 = i;
    if (pool_[i] == e2) idx2 = i;
  }
  if (idx1 < 0 || idx2 < 0) return false;
  idx2 -= kHalfPool;
  if (idx2 < 0) return false;
  transformed = idx1;
  charIndex = idx2;
  return true;
}

std::string CipherEngine::encrypt(const std::string& plaintext) {
  resetRotors();
  std::string buffer;
  for (unsigned char ch : plaintext) {
    const int charIndex = charsetIndex(static_cast<char>(ch));
    if (charIndex < 0) continue;
    stepRotors();
    const int transformed = transform(charIndex);
    buffer += toEmojiPair(charIndex, transformed);
    for (int j = 0; j < complexity_ - 2; ++j) {
      const int idx = (rI_.position + charIndex + j * 17) % kHalfPool;
      appendUtf8(buffer, pool_[idx]);
    }
  }
  return buffer;
}

std::string CipherEngine::decrypt(const std::string& emojiText) {
  resetRotors();
  const auto runes = utf8ToCodepoints(emojiText);
  std::string buffer;
  size_t i = 0;
  const size_t step = static_cast<size_t>(complexity_);
  while (i + step <= runes.size()) {
    const uint32_t e1 = runes[i];
    const uint32_t e2 = runes[i + 1];
    i += step;
    int transformed = 0;
    int charIndex = 0;
    if (!fromEmojiPair(e1, e2, transformed, charIndex)) continue;
    stepRotors();
    const std::string cs = kCharset;
    if (charIndex >= 0 && charIndex < static_cast<int>(cs.size()) &&
        transform(charIndex) == transformed) {
      buffer.push_back(cs[static_cast<size_t>(charIndex)]);
    }
  }
  return buffer;
}

}  // namespace polybius
