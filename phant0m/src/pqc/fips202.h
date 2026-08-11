#pragma once

#include <stdint.h>
#include <stddef.h>

// Compact FIPS-202 SHA3 / SHAKE for Kyber.
namespace phant0m {
namespace shake {

void sha3_256(uint8_t out[32], const uint8_t *in, size_t inlen);
void sha3_512(uint8_t out[64], const uint8_t *in, size_t inlen);
void shake128(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen);
void shake256(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen);

class Shake128Inc {
 public:
  void init();
  void absorb(const uint8_t *in, size_t inlen);
  void finalize();
  void squeeze(uint8_t *out, size_t outlen);

 private:
  uint64_t s_[25];
  size_t pos_;
};

class Shake256Inc {
 public:
  void init();
  void absorb(const uint8_t *in, size_t inlen);
  void finalize();
  void squeeze(uint8_t *out, size_t outlen);

 private:
  uint64_t s_[25];
  size_t pos_;
};

}  // namespace shake
}  // namespace phant0m
