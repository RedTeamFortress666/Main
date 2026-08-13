#include "polybius/sha256.h"

#include <cstdio>
#include <sstream>
#include <iomanip>
#include <vector>

#if defined(ESP_PLATFORM) || defined(ARDUINO)
#include "mbedtls/sha256.h"
#else
#include <openssl/sha.h>
#endif

#include "polybius/utf8_util.h"

namespace polybius {

std::array<uint8_t, 32> sha256Bytes(const uint8_t* data, size_t len) {
  std::array<uint8_t, 32> out{};
#if defined(ESP_PLATFORM) || defined(ARDUINO)
  mbedtls_sha256_context ctx;
  mbedtls_sha256_init(&ctx);
  mbedtls_sha256_starts(&ctx, 0);
  mbedtls_sha256_update(&ctx, data, len);
  mbedtls_sha256_finish(&ctx, out.data());
  mbedtls_sha256_free(&ctx);
#else
  SHA256(data, len, out.data());
#endif
  return out;
}

std::string sha256Hex(const uint8_t* data, size_t len) {
  const auto dig = sha256Bytes(data, len);
  std::ostringstream oss;
  for (uint8_t b : dig) {
    oss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(b);
  }
  return oss.str();
}

std::array<uint8_t, 32> sha256Utf16CodeUnits(const std::string& utf8) {
  // Rotor keys are ASCII; Dart `sha256.convert(codeUnits)` hashes each
  // code unit as one byte for values < 256.
  std::vector<uint8_t> bytes;
  for (uint32_t cp : utf8ToCodepoints(utf8)) {
    if (cp <= 0xFF) bytes.push_back(static_cast<uint8_t>(cp));
  }
  return sha256Bytes(bytes.data(), bytes.size());
}

}  // namespace polybius
