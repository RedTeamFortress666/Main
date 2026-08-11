#pragma once

#include <stdint.h>
#include <stddef.h>

// Compact CRYSTALS-Kyber512 KEM (NIST PQC).
// Math is software NTT; entropy/KDF path uses ESP32 HW RNG + SHAKE.
// Keygen + Encaps are the field-critical paths for Phant0m handshakes.

namespace phant0m {
namespace kyber512 {

constexpr size_t PUBLICKEY_BYTES = 800;
constexpr size_t SECRETKEY_BYTES = 1632;
constexpr size_t CIPHERTEXT_BYTES = 768;
constexpr size_t SHAREDSECRET_BYTES = 32;
constexpr size_t SYMBYTES = 32;

// Fill `randombytes` from solar-entropy DRBG before calling.
using RandomFn = void (*)(uint8_t *out, size_t len);

void set_random(RandomFn fn);

int keygen(uint8_t pk[PUBLICKEY_BYTES], uint8_t sk[SECRETKEY_BYTES]);
int encaps(uint8_t ct[CIPHERTEXT_BYTES], uint8_t ss[SHAREDSECRET_BYTES],
           const uint8_t pk[PUBLICKEY_BYTES]);
int decaps(uint8_t ss[SHAREDSECRET_BYTES], const uint8_t ct[CIPHERTEXT_BYTES],
           const uint8_t sk[SECRETKEY_BYTES]);

}  // namespace kyber512
}  // namespace phant0m
