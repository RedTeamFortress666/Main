#pragma once

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

namespace polybius {

/// Multi-rotor Enigma variant matching Flutter `CipherEngine`.
class CipherEngine {
 public:
  static constexpr const char* kCharset =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,!?-_:;@#$%&*+/=";

  CipherEngine(std::string seed, int complexity = 2);

  const std::string& seed() const { return seed_; }
  int complexity() const { return complexity_; }
  std::string poolId() const;
  const std::vector<uint32_t>& pool() const { return pool_; }

  std::string encrypt(const std::string& plaintext);
  std::string decrypt(const std::string& emojiText);

 private:
  std::string seed_;
  int complexity_;
  std::vector<uint32_t> pool_;
  std::vector<int> reflector_;
  // Rotors recreated on each encrypt/decrypt via reset.
  void resetRotors();
  void stepRotors();
  int transform(int input);
  std::string toEmojiPair(int charIndex, int transformed) const;
  bool fromEmojiPair(uint32_t e1, uint32_t e2, int& transformed, int& charIndex) const;

  // Mutable rotor state for a single pass.
  struct RotorState {
    std::vector<int> wiring;
    int notch = 0;
    int position = 0;
    int forward(int input) const;
    int backward(int input) const;
    void step();
    bool atNotch() const { return position == notch; }
  };
  RotorState rI_, rII_, rIII_;

  static std::vector<int> buildReflector(const std::string& dateKey);
  static int charsetIndex(char c);
};

}  // namespace polybius
