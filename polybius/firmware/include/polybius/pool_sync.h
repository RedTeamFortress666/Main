#pragma once

#include <cstdint>
#include <optional>
#include <string>

namespace polybius {

struct PoolSync {
  std::string poolId;
  std::string seed;
  int64_t expiresAtMs = 0;
  std::string emojiPoolHash;
  int complexity = 2;

  bool isExpired(int64_t nowMs) const { return nowMs > expiresAtMs; }
  bool verifyIntegrity() const;
  std::string encode() const;

  static std::optional<PoolSync> tryParse(const std::string& raw);
  static PoolSync fromSeed(const std::string& seed, int complexity = 2,
                           int64_t windowMs = 6LL * 3600 * 1000,
                           int64_t nowMs = 0);
  static std::string poolIdFor(const std::string& seed);
  static std::string poolHashFor(const std::string& seed);
};

}  // namespace polybius
