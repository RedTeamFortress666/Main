#include "fips202.h"
#include <string.h>

namespace phant0m {
namespace shake {
namespace {

constexpr size_t SHAKE128_RATE = 168;
constexpr size_t SHAKE256_RATE = 136;
constexpr size_t SHA3_256_RATE = 136;
constexpr size_t SHA3_512_RATE = 72;

inline uint64_t rotl64(uint64_t x, int n) { return (x << n) | (x >> (64 - n)); }

void keccak_f1600(uint64_t s[25]) {
  static const uint64_t RC[24] = {
      0x0000000000000001ULL, 0x0000000000008082ULL, 0x800000000000808aULL,
      0x8000000080008000ULL, 0x000000000000808bULL, 0x0000000080000001ULL,
      0x8000000080008081ULL, 0x8000000000008009ULL, 0x000000000000008aULL,
      0x0000000000000088ULL, 0x0000000080008009ULL, 0x000000008000000aULL,
      0x000000008000808bULL, 0x800000000000008bULL, 0x8000000000008089ULL,
      0x8000000000008003ULL, 0x8000000000008002ULL, 0x8000000000000080ULL,
      0x000000000000800aULL, 0x800000008000000aULL, 0x8000000080008081ULL,
      0x8000000000008080ULL, 0x0000000080000001ULL, 0x8000000080008008ULL};
  static const int ROT[24] = {1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
                              27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44};
  static const int PIL[24] = {10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
                              15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1};

  for (int round = 0; round < 24; ++round) {
    uint64_t bc[5];
    for (int i = 0; i < 5; ++i)
      bc[i] = s[i] ^ s[i + 5] ^ s[i + 10] ^ s[i + 15] ^ s[i + 20];
    for (int i = 0; i < 5; ++i) {
      const uint64_t t = bc[(i + 4) % 5] ^ rotl64(bc[(i + 1) % 5], 1);
      for (int j = 0; j < 25; j += 5) s[j + i] ^= t;
    }
    uint64_t t = s[1];
    for (int i = 0; i < 24; ++i) {
      const int j = PIL[i];
      bc[0] = s[j];
      s[j] = rotl64(t, ROT[i]);
      t = bc[0];
    }
    for (int j = 0; j < 25; j += 5) {
      for (int i = 0; i < 5; ++i) bc[i] = s[j + i];
      for (int i = 0; i < 5; ++i)
        s[j + i] = bc[i] ^ ((~bc[(i + 1) % 5]) & bc[(i + 2) % 5]);
    }
    s[0] ^= RC[round];
  }
}

void absorb_once(uint64_t s[25], const uint8_t *in, size_t inlen, size_t rate,
                 uint8_t pad) {
  memset(s, 0, 25 * sizeof(uint64_t));
  while (inlen >= rate) {
    for (size_t i = 0; i < rate / 8; ++i) {
      uint64_t v = 0;
      memcpy(&v, in + 8 * i, 8);
      s[i] ^= v;
    }
    keccak_f1600(s);
    in += rate;
    inlen -= rate;
  }
  uint8_t tmp[168];
  memset(tmp, 0, rate);
  memcpy(tmp, in, inlen);
  tmp[inlen] = pad;
  tmp[rate - 1] |= 0x80;
  for (size_t i = 0; i < rate / 8; ++i) {
    uint64_t v = 0;
    memcpy(&v, tmp + 8 * i, 8);
    s[i] ^= v;
  }
  keccak_f1600(s);
}

void squeeze(uint64_t s[25], uint8_t *out, size_t outlen, size_t rate) {
  while (outlen > 0) {
    const size_t n = outlen < rate ? outlen : rate;
    memcpy(out, s, n);
    out += n;
    outlen -= n;
    if (outlen) keccak_f1600(s);
  }
}

template <size_t Rate>
void inc_absorb(uint64_t s[25], size_t &pos, const uint8_t *in, size_t inlen) {
  auto *sb = reinterpret_cast<uint8_t *>(s);
  while (inlen > 0) {
    const size_t n = (Rate - pos) < inlen ? (Rate - pos) : inlen;
    for (size_t i = 0; i < n; ++i) sb[pos + i] ^= in[i];
    pos += n;
    in += n;
    inlen -= n;
    if (pos == Rate) {
      keccak_f1600(s);
      pos = 0;
    }
  }
}

template <size_t Rate>
void inc_finalize(uint64_t s[25], size_t &pos, uint8_t pad) {
  auto *sb = reinterpret_cast<uint8_t *>(s);
  sb[pos] ^= pad;
  sb[Rate - 1] ^= 0x80;
  keccak_f1600(s);
  pos = 0;
}

template <size_t Rate>
void inc_squeeze(uint64_t s[25], size_t &pos, uint8_t *out, size_t outlen) {
  auto *sb = reinterpret_cast<uint8_t *>(s);
  while (outlen > 0) {
    if (pos == Rate) {
      keccak_f1600(s);
      pos = 0;
    }
    const size_t n = (Rate - pos) < outlen ? (Rate - pos) : outlen;
    memcpy(out, sb + pos, n);
    pos += n;
    out += n;
    outlen -= n;
  }
}

}  // namespace

void sha3_256(uint8_t out[32], const uint8_t *in, size_t inlen) {
  uint64_t s[25];
  absorb_once(s, in, inlen, SHA3_256_RATE, 0x06);
  memcpy(out, s, 32);
}

void sha3_512(uint8_t out[64], const uint8_t *in, size_t inlen) {
  uint64_t s[25];
  absorb_once(s, in, inlen, SHA3_512_RATE, 0x06);
  memcpy(out, s, 64);
}

void shake128(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen) {
  uint64_t s[25];
  absorb_once(s, in, inlen, SHAKE128_RATE, 0x1f);
  squeeze(s, out, outlen, SHAKE128_RATE);
}

void shake256(uint8_t *out, size_t outlen, const uint8_t *in, size_t inlen) {
  uint64_t s[25];
  absorb_once(s, in, inlen, SHAKE256_RATE, 0x1f);
  squeeze(s, out, outlen, SHAKE256_RATE);
}

void Shake128Inc::init() {
  memset(s_, 0, sizeof(s_));
  pos_ = 0;
}
void Shake128Inc::absorb(const uint8_t *in, size_t inlen) {
  inc_absorb<SHAKE128_RATE>(s_, pos_, in, inlen);
}
void Shake128Inc::finalize() { inc_finalize<SHAKE128_RATE>(s_, pos_, 0x1f); }
void Shake128Inc::squeeze(uint8_t *out, size_t outlen) {
  inc_squeeze<SHAKE128_RATE>(s_, pos_, out, outlen);
}

void Shake256Inc::init() {
  memset(s_, 0, sizeof(s_));
  pos_ = 0;
}
void Shake256Inc::absorb(const uint8_t *in, size_t inlen) {
  inc_absorb<SHAKE256_RATE>(s_, pos_, in, inlen);
}
void Shake256Inc::finalize() { inc_finalize<SHAKE256_RATE>(s_, pos_, 0x1f); }
void Shake256Inc::squeeze(uint8_t *out, size_t outlen) {
  inc_squeeze<SHAKE256_RATE>(s_, pos_, out, outlen);
}

}  // namespace shake
}  // namespace phant0m
