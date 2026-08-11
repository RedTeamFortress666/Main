#include "kyber512.h"
#include "fips202.h"
#include <string.h>

// Compact Kyber-512 (k=2, eta1=3, eta2=2, du=10, dv=4) — size-optimized ref.

namespace phant0m {
namespace kyber512 {
namespace {

constexpr int N = 256;
constexpr int Q = 3329;
constexpr int K = 2;
constexpr int ETA1 = 3;
constexpr int ETA2 = 2;
constexpr int DU = 10;
constexpr int DV = 4;
constexpr int POLYBYTES = 384;
constexpr int POLYVECBYTES = K * POLYBYTES;
constexpr int POLYCOMPRESSEDBYTES = 128;
constexpr int POLYVECCOMPRESSEDBYTES = K * 320;

using Poly = int16_t[N];
using PolyVec = Poly[K];

RandomFn g_random = nullptr;

constexpr int16_t ZETAS[128] = {
    2285, 2156, 2343,  383, 2768, 1571, -402, 1536, -541, -650,  -682, 1476,
    1015, 2035,  379, 2229, 2028, 1875, 1630,  523, 2419, -709, -1840, 1795,
   -1469,  959, 1521, 1193, -1360, 2166, -380, -273, 1102, -2545, 1409, 1601,
   -1051, 2017,  187,  441, 1464,  -629, 1157, -3064,  635, -551,  598,  609,
   -2411, 1759, -2200, 2908,  602, 2814, 1575,  288, -2197, -416, 2986, -273,
   -1050,  844, 2117, 2095, -1001, 3083,  552, 2734,  163,  3097, -157, -505,
   -2087, -1815, 2839,  758, -3021, 1129, -842,  1435,  2031, 1876,  1645,
    2455, -1631,  989, -1929,  268, -641,  2126, -1873,  -425, 1092, -1343,
   -1033,  296, 1175, 1023, -2507,  855, -2245, -479,  243,  1786,  581,
   -2418, -1696,  743, 2692,  1801,  -524, 1993,  2509,  2372, -2141,  869,
   -1606,  632,  -947,  348, 1506,  2151,  -432, 2053, -1482, -868,  2861};

int16_t montgomery_reduce(int32_t a) {
  const int16_t u = static_cast<int16_t>(a * 62209);
  int32_t t = static_cast<int32_t>(u) * Q;
  t = a - t;
  t >>= 16;
  return static_cast<int16_t>(t);
}

int16_t barrett_reduce(int16_t a) {
  const int16_t v = ((static_cast<int32_t>(a) + (1 << 25)) >> 26);
  return static_cast<int16_t>(a - v * Q);
}

void ntt(int16_t r[N]) {
  int k = 1;
  for (int len = 128; len >= 2; len >>= 1) {
    for (int start = 0; start < N; start += 2 * len) {
      const int16_t zeta = ZETAS[k++];
      for (int j = start; j < start + len; ++j) {
        const int16_t t = montgomery_reduce(static_cast<int32_t>(zeta) * r[j + len]);
        r[j + len] = r[j] - t;
        r[j] = r[j] + t;
      }
    }
  }
}

void invntt(int16_t r[N]) {
  int k = 127;
  for (int len = 2; len <= 128; len <<= 1) {
    for (int start = 0; start < N; start += 2 * len) {
      const int16_t zeta = ZETAS[k--];
      for (int j = start; j < start + len; ++j) {
        const int16_t t = r[j];
        r[j] = barrett_reduce(t + r[j + len]);
        r[j + len] = r[j + len] - t;
        r[j + len] = montgomery_reduce(static_cast<int32_t>(zeta) * r[j + len]);
      }
    }
  }
  for (int j = 0; j < N; ++j)
    r[j] = montgomery_reduce(static_cast<int32_t>(r[j]) * 1441);
}

void basemul(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta) {
  r[0] = montgomery_reduce(static_cast<int32_t>(a[1]) * b[1]);
  r[0] = montgomery_reduce(static_cast<int32_t>(r[0]) * zeta);
  r[0] += montgomery_reduce(static_cast<int32_t>(a[0]) * b[0]);
  r[1] = montgomery_reduce(static_cast<int32_t>(a[0]) * b[1]);
  r[1] += montgomery_reduce(static_cast<int32_t>(a[1]) * b[0]);
}

void poly_basemul_montgomery(Poly &r, const Poly &a, const Poly &b) {
  for (int i = 0; i < N / 4; ++i) {
    basemul(&r[4 * i], &a[4 * i], &b[4 * i], ZETAS[64 + i]);
    basemul(&r[4 * i + 2], &a[4 * i + 2], &b[4 * i + 2],
            static_cast<int16_t>(-ZETAS[64 + i]));
  }
}

void poly_tomont(Poly &r) {
  const int16_t f = 1353;
  for (int i = 0; i < N; ++i)
    r[i] = montgomery_reduce(static_cast<int32_t>(r[i]) * f);
}

void poly_reduce(Poly &r) {
  for (int i = 0; i < N; ++i) r[i] = barrett_reduce(r[i]);
}

void poly_add(Poly &r, const Poly &a, const Poly &b) {
  for (int i = 0; i < N; ++i) r[i] = a[i] + b[i];
}

void poly_sub(Poly &r, const Poly &a, const Poly &b) {
  for (int i = 0; i < N; ++i) r[i] = a[i] - b[i];
}

void poly_ntt(Poly &r) { ntt(r); poly_reduce(r); }
void poly_invntt_tomont(Poly &r) { invntt(r); }

void polyvec_ntt(PolyVec &r) {
  for (int i = 0; i < K; ++i) poly_ntt(r[i]);
}
void polyvec_invntt_tomont(PolyVec &r) {
  for (int i = 0; i < K; ++i) poly_invntt_tomont(r[i]);
}
void polyvec_add(PolyVec &r, const PolyVec &a, const PolyVec &b) {
  for (int i = 0; i < K; ++i) poly_add(r[i], a[i], b[i]);
}
void polyvec_reduce(PolyVec &r) {
  for (int i = 0; i < K; ++i) poly_reduce(r[i]);
}

void polyvec_basemul_acc_montgomery(Poly &r, const PolyVec &a, const PolyVec &b) {
  Poly t;
  poly_basemul_montgomery(r, a[0], b[0]);
  for (int i = 1; i < K; ++i) {
    poly_basemul_montgomery(t, a[i], b[i]);
    poly_add(r, r, t);
  }
  poly_reduce(r);
}

void cbd(Poly &r, const uint8_t *buf, int eta) {
  if (eta == 2) {
    for (int i = 0; i < N / 8; ++i) {
      uint32_t t =
          static_cast<uint32_t>(buf[4 * i]) |
          (static_cast<uint32_t>(buf[4 * i + 1]) << 8) |
          (static_cast<uint32_t>(buf[4 * i + 2]) << 16) |
          (static_cast<uint32_t>(buf[4 * i + 3]) << 24);
      uint32_t d = t & 0x55555555u;
      d += (t >> 1) & 0x55555555u;
      for (int j = 0; j < 8; ++j) {
        const int16_t a = (d >> (4 * j)) & 0x3;
        const int16_t b = (d >> (4 * j + 2)) & 0x3;
        r[8 * i + j] = a - b;
      }
    }
  } else {  // eta == 3
    for (int i = 0; i < N / 4; ++i) {
      uint32_t t =
          static_cast<uint32_t>(buf[3 * i]) |
          (static_cast<uint32_t>(buf[3 * i + 1]) << 8) |
          (static_cast<uint32_t>(buf[3 * i + 2]) << 16);
      uint32_t d = t & 0x00249249u;
      d += (t >> 1) & 0x00249249u;
      d += (t >> 2) & 0x00249249u;
      for (int j = 0; j < 4; ++j) {
        const int16_t a = (d >> (6 * j)) & 0x7;
        const int16_t b = (d >> (6 * j + 3)) & 0x7;
        r[4 * i + j] = a - b;
      }
    }
  }
}

void poly_getnoise_eta1(Poly &r, const uint8_t seed[SYMBYTES], uint8_t nonce) {
  uint8_t buf[ETA1 * N / 4];
  uint8_t ext[SYMBYTES + 1];
  memcpy(ext, seed, SYMBYTES);
  ext[SYMBYTES] = nonce;
  shake::shake256(buf, sizeof(buf), ext, sizeof(ext));
  cbd(r, buf, ETA1);
}

void poly_getnoise_eta2(Poly &r, const uint8_t seed[SYMBYTES], uint8_t nonce) {
  uint8_t buf[ETA2 * N / 4];
  uint8_t ext[SYMBYTES + 1];
  memcpy(ext, seed, SYMBYTES);
  ext[SYMBYTES] = nonce;
  shake::shake256(buf, sizeof(buf), ext, sizeof(ext));
  cbd(r, buf, ETA2);
}

void poly_compress(uint8_t *r, const Poly &a) {
  uint8_t t[8];
  int16_t u;
  size_t off = 0;
  for (int i = 0; i < N / 8; ++i) {
    for (int j = 0; j < 8; ++j) {
      u = a[8 * i + j];
      u += (u >> 15) & Q;
      t[j] = static_cast<uint8_t>((((static_cast<uint32_t>(u) << DV) + Q / 2) / Q) & 15);
    }
    r[off + 0] = t[0] | (t[1] << 4);
    r[off + 1] = t[2] | (t[3] << 4);
    r[off + 2] = t[4] | (t[5] << 4);
    r[off + 3] = t[6] | (t[7] << 4);
    off += 4;
  }
}

void poly_decompress(Poly &r, const uint8_t *a) {
  for (int i = 0; i < N / 2; ++i) {
    r[2 * i] = static_cast<int16_t>((((uint16_t)(a[i] & 15) * Q) + 8) >> 4);
    r[2 * i + 1] =
        static_cast<int16_t>((((uint16_t)(a[i] >> 4) * Q) + 8) >> 4);
  }
}

void polyvec_compress(uint8_t *r, const PolyVec &a) {
  uint16_t t[4];
  size_t off = 0;
  for (int i = 0; i < K; ++i) {
    for (int j = 0; j < N / 4; ++j) {
      for (int k = 0; k < 4; ++k) {
        int16_t u = a[i][4 * j + k];
        u += (u >> 15) & Q;
        t[k] = ((((uint32_t)u << DU) + Q / 2) / Q) & 0x3ff;
      }
      r[off + 0] = t[0];
      r[off + 1] = (t[0] >> 8) | (t[1] << 2);
      r[off + 2] = (t[1] >> 6) | (t[2] << 4);
      r[off + 3] = (t[2] >> 4) | (t[3] << 6);
      r[off + 4] = t[3] >> 2;
      off += 5;
    }
  }
}

void polyvec_decompress(PolyVec &r, const uint8_t *a) {
  size_t off = 0;
  for (int i = 0; i < K; ++i) {
    for (int j = 0; j < N / 4; ++j) {
      uint16_t t[4];
      t[0] = a[off] | ((uint16_t)(a[off + 1] & 0x03) << 8);
      t[1] = (a[off + 1] >> 2) | ((uint16_t)(a[off + 2] & 0x0f) << 6);
      t[2] = (a[off + 2] >> 4) | ((uint16_t)(a[off + 3] & 0x3f) << 4);
      t[3] = (a[off + 3] >> 6) | ((uint16_t)a[off + 4] << 2);
      off += 5;
      for (int k = 0; k < 4; ++k)
        r[i][4 * j + k] =
            static_cast<int16_t>(((uint32_t)(t[k] & 0x3FF) * Q + 512) >> 10);
    }
  }
}

void poly_tobytes(uint8_t r[POLYBYTES], const Poly &a) {
  uint16_t t0, t1;
  for (int i = 0; i < N / 2; ++i) {
    int16_t u0 = a[2 * i];
    u0 += (u0 >> 15) & Q;
    int16_t u1 = a[2 * i + 1];
    u1 += (u1 >> 15) & Q;
    t0 = u0;
    t1 = u1;
    r[3 * i] = t0;
    r[3 * i + 1] = (t0 >> 8) | (t1 << 4);
    r[3 * i + 2] = t1 >> 4;
  }
}

void poly_frombytes(Poly &r, const uint8_t a[POLYBYTES]) {
  for (int i = 0; i < N / 2; ++i) {
    r[2 * i] = ((a[3 * i] >> 0) | ((uint16_t)a[3 * i + 1] << 8)) & 0xFFF;
    r[2 * i + 1] =
        ((a[3 * i + 1] >> 4) | ((uint16_t)a[3 * i + 2] << 4)) & 0xFFF;
  }
}

void polyvec_tobytes(uint8_t r[POLYVECBYTES], const PolyVec &a) {
  for (int i = 0; i < K; ++i) poly_tobytes(r + i * POLYBYTES, a[i]);
}
void polyvec_frombytes(PolyVec &r, const uint8_t a[POLYVECBYTES]) {
  for (int i = 0; i < K; ++i) poly_frombytes(r[i], a + i * POLYBYTES);
}

void gen_matrix(PolyVec a[K], const uint8_t seed[SYMBYTES], int transposed) {
  uint8_t buf[504];
  uint8_t extkey[SYMBYTES + 2];
  memcpy(extkey, seed, SYMBYTES);
  for (int i = 0; i < K; ++i) {
    for (int j = 0; j < K; ++j) {
      if (transposed) {
        extkey[SYMBYTES] = i;
        extkey[SYMBYTES + 1] = j;
      } else {
        extkey[SYMBYTES] = j;
        extkey[SYMBYTES + 1] = i;
      }
      shake::Shake128Inc xof;
      xof.init();
      xof.absorb(extkey, sizeof(extkey));
      xof.finalize();
      xof.squeeze(buf, sizeof(buf));
      size_t ctr = 0, bufoff = 0;
      while (ctr < N) {
        const uint16_t val = buf[bufoff] | ((uint16_t)buf[bufoff + 1] << 8);
        bufoff += 2;
        if (bufoff >= sizeof(buf)) {
          xof.squeeze(buf, sizeof(buf));
          bufoff = 0;
        }
        if (val < 19 * Q) {
          a[i][j][ctr++] = val % Q;
        }
      }
    }
  }
}

void hash_h(uint8_t out[SYMBYTES], const uint8_t *in, size_t inlen) {
  shake::sha3_256(out, in, inlen);
}

void hash_g(uint8_t out[64], const uint8_t *in, size_t inlen) {
  shake::sha3_512(out, in, inlen);
}

void kdf(uint8_t out[SYMBYTES], const uint8_t *in, size_t inlen) {
  shake::shake256(out, SYMBYTES, in, inlen);
}

void indcpa_keypair(uint8_t pk[PUBLICKEY_BYTES], uint8_t sk[POLYVECBYTES]) {
  uint8_t buf[64];
  g_random(buf, SYMBYTES);
  hash_g(buf, buf, SYMBYTES);
  const uint8_t *publicseed = buf;
  const uint8_t *noiseseed = buf + SYMBYTES;

  PolyVec a[K], e, pkpv, skpv;
  gen_matrix(a, publicseed, 0);
  for (uint8_t i = 0; i < K; ++i) poly_getnoise_eta1(skpv[i], noiseseed, i);
  for (uint8_t i = 0; i < K; ++i) poly_getnoise_eta1(e[i], noiseseed, i + K);
  polyvec_ntt(skpv);
  polyvec_ntt(e);
  for (int i = 0; i < K; ++i) {
    polyvec_basemul_acc_montgomery(pkpv[i], a[i], skpv);
    poly_tomont(pkpv[i]);
  }
  polyvec_add(pkpv, pkpv, e);
  polyvec_reduce(pkpv);
  polyvec_tobytes(sk, skpv);
  polyvec_tobytes(pk, pkpv);
  memcpy(pk + POLYVECBYTES, publicseed, SYMBYTES);
}

void indcpa_enc(uint8_t c[CIPHERTEXT_BYTES], const uint8_t m[SYMBYTES],
                const uint8_t pk[PUBLICKEY_BYTES], const uint8_t coins[SYMBYTES]) {
  PolyVec sp, pkpv, ep, at[K], b;
  Poly v, k, epp;
  polyvec_frombytes(pkpv, pk);
  const uint8_t *seed = pk + POLYVECBYTES;
  gen_matrix(at, seed, 1);

  for (int i = 0; i < SYMBYTES; ++i) {
    for (int j = 0; j < 8; ++j)
      k[8 * i + j] = ((m[i] >> j) & 1) * ((Q + 1) / 2);
  }

  for (uint8_t i = 0; i < K; ++i) poly_getnoise_eta1(sp[i], coins, i);
  for (uint8_t i = 0; i < K; ++i) poly_getnoise_eta2(ep[i], coins, i + K);
  poly_getnoise_eta2(epp, coins, 2 * K);

  polyvec_ntt(sp);
  for (int i = 0; i < K; ++i) polyvec_basemul_acc_montgomery(b[i], at[i], sp);
  polyvec_basemul_acc_montgomery(v, pkpv, sp);
  polyvec_invntt_tomont(b);
  poly_invntt_tomont(v);
  polyvec_add(b, b, ep);
  poly_add(v, v, epp);
  poly_add(v, v, k);
  polyvec_reduce(b);
  poly_reduce(v);
  polyvec_compress(c, b);
  poly_compress(c + POLYVECCOMPRESSEDBYTES, v);
}

void indcpa_dec(uint8_t m[SYMBYTES], const uint8_t c[CIPHERTEXT_BYTES],
                const uint8_t sk[POLYVECBYTES]) {
  PolyVec b, skpv;
  Poly v, mp;
  polyvec_decompress(b, c);
  poly_decompress(v, c + POLYVECCOMPRESSEDBYTES);
  polyvec_frombytes(skpv, sk);
  polyvec_ntt(b);
  polyvec_basemul_acc_montgomery(mp, skpv, b);
  poly_invntt_tomont(mp);
  poly_sub(mp, v, mp);
  poly_reduce(mp);
  for (int i = 0; i < SYMBYTES; ++i) {
    m[i] = 0;
    for (int j = 0; j < 8; ++j) {
      int16_t t = (((int16_t)mp[8 * i + j] << 1) + Q / 2) / Q;
      m[i] |= (t & 1) << j;
    }
  }
}

int verify(const uint8_t *a, const uint8_t *b, size_t len) {
  uint8_t r = 0;
  for (size_t i = 0; i < len; ++i) r |= a[i] ^ b[i];
  return (-static_cast<int>(r)) >> 31;
}

void cmov(uint8_t *r, const uint8_t *x, size_t len, uint8_t b) {
  b = -b;
  for (size_t i = 0; i < len; ++i) r[i] ^= b & (r[i] ^ x[i]);
}

}  // namespace

void set_random(RandomFn fn) { g_random = fn; }

int keygen(uint8_t pk[PUBLICKEY_BYTES], uint8_t sk[SECRETKEY_BYTES]) {
  if (!g_random) return -1;
  indcpa_keypair(pk, sk);
  memcpy(sk + POLYVECBYTES, pk, PUBLICKEY_BYTES);
  hash_h(sk + POLYVECBYTES + PUBLICKEY_BYTES, pk, PUBLICKEY_BYTES);
  g_random(sk + POLYVECBYTES + PUBLICKEY_BYTES + SYMBYTES, SYMBYTES);
  return 0;
}

int encaps(uint8_t ct[CIPHERTEXT_BYTES], uint8_t ss[SHAREDSECRET_BYTES],
           const uint8_t pk[PUBLICKEY_BYTES]) {
  if (!g_random) return -1;
  uint8_t buf[64];
  uint8_t kr[64];
  g_random(buf, SYMBYTES);
  hash_h(buf, buf, SYMBYTES);  // don't leak coins
  hash_h(buf + SYMBYTES, pk, PUBLICKEY_BYTES);
  hash_g(kr, buf, 64);
  indcpa_enc(ct, buf, pk, kr + SYMBYTES);
  hash_h(kr + SYMBYTES, ct, CIPHERTEXT_BYTES);
  kdf(ss, kr, 64);
  return 0;
}

int decaps(uint8_t ss[SHAREDSECRET_BYTES], const uint8_t ct[CIPHERTEXT_BYTES],
           const uint8_t sk[SECRETKEY_BYTES]) {
  uint8_t buf[64];
  uint8_t kr[64];
  uint8_t cmp[CIPHERTEXT_BYTES];
  const uint8_t *pk = sk + POLYVECBYTES;
  indcpa_dec(buf, ct, sk);
  memcpy(buf + SYMBYTES, sk + POLYVECBYTES + PUBLICKEY_BYTES, SYMBYTES);
  hash_g(kr, buf, 64);
  indcpa_enc(cmp, buf, pk, kr + SYMBYTES);
  const int fail = verify(ct, cmp, CIPHERTEXT_BYTES);
  hash_h(kr + SYMBYTES, ct, CIPHERTEXT_BYTES);
  cmov(kr, sk + POLYVECBYTES + PUBLICKEY_BYTES + SYMBYTES, SYMBYTES,
       static_cast<uint8_t>(fail));
  kdf(ss, kr, 64);
  return 0;
}

}  // namespace kyber512
}  // namespace phant0m
