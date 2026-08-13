#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <vector>

namespace polybius {

/// Thin SHA-256 wrapper (mbedTLS on-device, OpenSSL on host tests).
std::array<uint8_t, 32> sha256Bytes(const uint8_t* data, size_t len);
inline std::array<uint8_t, 32> sha256Bytes(const std::string& s) {
  return sha256Bytes(reinterpret_cast<const uint8_t*>(s.data()), s.size());
}
inline std::array<uint8_t, 32> sha256Bytes(const std::vector<uint8_t>& v) {
  return sha256Bytes(v.data(), v.size());
}

std::string sha256Hex(const uint8_t* data, size_t len);
inline std::string sha256Hex(const std::string& s) {
  return sha256Hex(reinterpret_cast<const uint8_t*>(s.data()), s.size());
}

/// SHA-256 over UTF-16 code units (Dart `String.codeUnits` for BMP).
std::array<uint8_t, 32> sha256Utf16CodeUnits(const std::string& utf8);

}  // namespace polybius
