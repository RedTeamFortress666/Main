#include "polybius/pool_sync.h"

#include "polybius/daily_pool.h"
#include "polybius/sha256.h"
#include "polybius/utf8_util.h"

#include <algorithm>
#include <cctype>
#include <cstring>
#include <sstream>
#include <vector>

namespace polybius {
namespace {

std::string base64UrlEncode(const std::string& in) {
  static const char* kTbl =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  std::string out;
  int val = 0;
  int valb = -6;
  for (unsigned char c : in) {
    val = (val << 8) + c;
    valb += 8;
    while (valb >= 0) {
      out.push_back(kTbl[(val >> valb) & 0x3F]);
      valb -= 6;
    }
  }
  if (valb > -6) out.push_back(kTbl[((val << 8) >> (valb + 8)) & 0x3F]);
  while (out.size() % 4) out.push_back('=');
  for (char& c : out) {
    if (c == '+') c = '-';
    else if (c == '/') c = '_';
  }
  while (!out.empty() && out.back() == '=') out.pop_back();
  return out;
}

std::string base64UrlDecode(std::string in) {
  for (char& c : in) {
    if (c == '-') c = '+';
    else if (c == '_') c = '/';
  }
  while (in.size() % 4) in.push_back('=');
  int8_t dec[256];
  std::fill(dec, dec + 256, static_cast<int8_t>(-1));
  const char* tbl =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  for (int i = 0; tbl[i]; ++i) {
    dec[static_cast<unsigned char>(tbl[i])] = static_cast<int8_t>(i);
  }
  std::string out;
  int val = 0;
  int valb = -8;
  for (unsigned char c : in) {
    if (c == '=') break;
    if (dec[c] == -1) continue;
    val = (val << 6) + dec[c];
    valb += 6;
    if (valb >= 0) {
      out.push_back(static_cast<char>((val >> valb) & 0xFF));
      valb -= 8;
    }
  }
  return out;
}

std::string jsonGetString(const std::string& json, const std::string& key) {
  const std::string pat = "\"" + key + "\"";
  auto pos = json.find(pat);
  if (pos == std::string::npos) return {};
  pos = json.find(':', pos);
  if (pos == std::string::npos) return {};
  pos = json.find('"', pos);
  if (pos == std::string::npos) return {};
  const auto end = json.find('"', pos + 1);
  if (end == std::string::npos) return {};
  return json.substr(pos + 1, end - pos - 1);
}

int64_t jsonGetInt(const std::string& json, const std::string& key, int64_t def = 0) {
  const std::string pat = "\"" + key + "\"";
  auto pos = json.find(pat);
  if (pos == std::string::npos) return def;
  pos = json.find(':', pos);
  if (pos == std::string::npos) return def;
  ++pos;
  while (pos < json.size() && (json[pos] == ' ' || json[pos] == '\t')) ++pos;
  try {
    return std::stoll(json.substr(pos));
  } catch (...) {
    return def;
  }
}

}  // namespace

std::string PoolSync::poolIdFor(const std::string& seed) {
  auto hex = sha256Hex(seed);
  std::transform(hex.begin(), hex.end(), hex.begin(),
                 [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
  return hex.substr(0, 12);
}

std::string PoolSync::poolHashFor(const std::string& seed) {
  const auto pool = DailyPool::generate(seed);
  std::string joined;
  joined.reserve(pool.size() * 4);
  for (uint32_t cp : pool) appendUtf8(joined, cp);
  return sha256Hex(joined).substr(0, 16);
}

bool PoolSync::verifyIntegrity() const {
  return poolHashFor(seed) == emojiPoolHash;
}

PoolSync PoolSync::fromSeed(const std::string& seed, int complexity,
                            int64_t windowMs, int64_t nowMs) {
  if (nowMs == 0) {
    // Caller should pass wall clock; default window from "now" unknown on host.
    nowMs = 0;
  }
  PoolSync t;
  t.poolId = poolIdFor(seed);
  t.seed = seed;
  t.expiresAtMs = nowMs + windowMs;
  t.emojiPoolHash = poolHashFor(seed);
  t.complexity = complexity < 2 ? 2 : (complexity > 6 ? 6 : complexity);
  return t;
}

std::string PoolSync::encode() const {
  std::ostringstream oss;
  oss << "{\"v\":1,\"pid\":\"" << poolId << "\",\"s\":\"" << seed
      << "\",\"e\":" << expiresAtMs << ",\"h\":\"" << emojiPoolHash
      << "\",\"c\":" << complexity << "}";
  return base64UrlEncode(oss.str());
}

std::optional<PoolSync> PoolSync::tryParse(const std::string& raw) {
  try {
    std::string trimmed = raw;
    while (!trimmed.empty() &&
           (trimmed.back() == '\n' || trimmed.back() == '\r' ||
            trimmed.back() == ' '))
      trimmed.pop_back();
    const std::string json = base64UrlDecode(trimmed);
    PoolSync t;
    t.poolId = jsonGetString(json, "pid");
    t.seed = jsonGetString(json, "s");
    t.expiresAtMs = jsonGetInt(json, "e");
    t.emojiPoolHash = jsonGetString(json, "h");
    t.complexity = static_cast<int>(jsonGetInt(json, "c", 2));
    if (t.poolId.empty() || t.seed.empty() || t.emojiPoolHash.empty()) {
      return std::nullopt;
    }
    return t;
  } catch (...) {
    return std::nullopt;
  }
}

}  // namespace polybius
