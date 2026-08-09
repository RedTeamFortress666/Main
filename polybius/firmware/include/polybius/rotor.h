#pragma once

#include <string>
#include <vector>

namespace polybius {

class Rotor {
 public:
  static constexpr int kAlphabetSize = 280;

  Rotor(std::string name, std::vector<int> wiring, int notch);

  static Rotor create(const std::string& name, const std::string& dateKey, int offset);

  void step();
  int forward(int input) const;
  int backward(int input) const;
  bool atNotch() const { return position_ == notch_; }

  int position() const { return position_; }
  int stepCount() const { return stepCount_; }
  int notch() const { return notch_; }
  const std::vector<int>& wiring() const { return wiring_; }

 private:
  std::string name_;
  std::vector<int> wiring_;
  int notch_ = 0;
  int position_ = 0;
  int stepCount_ = 0;
};

}  // namespace polybius
