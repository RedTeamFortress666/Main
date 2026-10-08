#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace polybius {

constexpr int kPoolSize = 560;
constexpr int kHalfPool = 280;

/// Builds the 560-emoji pool from a seed (matches Flutter DailyPool).
class DailyPool {
 public:
  explicit DailyPool(std::string seed);

  const std::string& seed() const { return seed_; }
  /// Pool as Unicode codepoints (one scalar each).
  const std::vector<uint32_t>& codepoints() const { return pool_; }
  /// Pool as UTF-8 emoji strings.
  std::vector<std::string> asUtf8() const;

  static std::vector<uint32_t> generate(const std::string& seed);

 private:
  std::string seed_;
  std::vector<uint32_t> pool_;
};

}  // namespace polybius
