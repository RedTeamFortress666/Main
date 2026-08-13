#pragma once

#include <cstdint>
#include <string>

namespace polybius {

/// Dart VM `String.hashCode` for one-byte / ASCII strings (wasm finalize).
inline uint32_t dartStringHash(const std::string& s) {
  if (s.empty()) return 1;
  uint32_t hash = 0;
  for (unsigned char c : s) {
    hash = (hash + c) & 0xFFFFFFFFu;
    hash = (hash + ((hash << 10) & 0xFFFFFFFFu)) & 0xFFFFFFFFu;
    hash ^= (hash >> 6);
  }
  hash = (hash + ((hash << 3) & 0xFFFFFFFFu)) & 0xFFFFFFFFu;
  hash ^= (hash >> 11);
  hash = (hash + ((hash << 15) & 0xFFFFFFFFu)) & 0xFFFFFFFFu;
  hash &= 0x3FFFFFFFu;
  return hash == 0 ? 1u : hash;
}

/// Dart VM `math.Random` — Multiply-With-Carry (dart:math `_Random`).
class DartRandom {
 public:
  explicit DartRandom(int64_t seed) : state_(setupSeed(seed)) {
    nextState();
    nextState();
    nextState();
    nextState();
  }

  int nextInt(int max) {
    constexpr uint64_t kPow2_32 = 1ull << 32;
    if (max <= 0) return 0;
    if ((max & -max) == max) {
      nextState();
      return static_cast<int>((state_ & 0xFFFFFFFFu) &
                             static_cast<uint32_t>(max - 1));
    }
    uint32_t rnd32;
    uint32_t result;
    do {
      nextState();
      rnd32 = static_cast<uint32_t>(state_ & 0xFFFFFFFFu);
      result = rnd32 % static_cast<uint32_t>(max);
    } while ((static_cast<uint64_t>(rnd32) - result +
              static_cast<uint32_t>(max)) > kPow2_32);
    return static_cast<int>(result);
  }

 private:
  uint64_t state_;

  static uint64_t setupSeed(int64_t n_in) {
    // Thomas Wang mix. Intermediates for our XOR-folded SHA seeds stay within
    // 64 bits until the final `n + (n<<31)`, which we reduce mod 2^64 via
    // multiply (matches Dart Random state).
    uint64_t n = static_cast<uint64_t>(n_in);
    n = (~n) + (n << 21);
    n = n ^ (n >> 24);
    n = n * 265u;
    n = n ^ (n >> 14);
    n = n * 21u;
    n = n ^ (n >> 28);
    n = n * 0x80000001ull;  // == n + (n << 31)  (mod 2^64)
    if (n == 0) n = 0x5a17;
    return n;
  }

  void nextState() {
    constexpr uint64_t A = 0xffffda61ull;
    const uint64_t lo = state_ & 0xFFFFFFFFu;
    const uint64_t hi = state_ >> 32;
    state_ = static_cast<uint64_t>(A * lo + hi);
  }
};

/// LCG used by Flutter `DailyPool._SeededRandom`.
class SeededLcg {
 public:
  explicit SeededLcg(int state)
      : state_(static_cast<uint32_t>(state) & 0x7fffffffu) {}

  int nextInt(int max) {
    state_ = (state_ * 1103515245u + 12345u) & 0x7fffffffu;
    if (max <= 0) return 0;
    return static_cast<int>(state_ % static_cast<uint32_t>(max));
  }

 private:
  uint32_t state_;
};

}  // namespace polybius
