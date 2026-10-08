#include "polybius/daily_pool.h"

#include "polybius/dart_compat.h"
#include "polybius/emoji_corpus.h"
#include "polybius/sha256.h"
#include "polybius/utf8_util.h"

#include <algorithm>

namespace polybius {

DailyPool::DailyPool(std::string seed) : seed_(std::move(seed)) {
  pool_ = generate(seed_);
}

std::vector<std::string> DailyPool::asUtf8() const {
  std::vector<std::string> out;
  out.reserve(pool_.size());
  for (uint32_t cp : pool_) out.push_back(utf8FromCodepoint(cp));
  return out;
}

std::vector<uint32_t> DailyPool::generate(const std::string& seed) {
  const auto dig = sha256Bytes(seed);
  int fold = 0;
  for (uint8_t b : dig) fold ^= static_cast<int>(b);
  SeededLcg rng(fold);

  std::vector<uint32_t> corpus(kEmojiCorpus, kEmojiCorpus + kEmojiCorpusCount);
  // Fisher–Yates matching Dart List.shuffle
  for (int i = static_cast<int>(corpus.size()); i > 1; --i) {
    const int j = rng.nextInt(i);
    std::swap(corpus[i - 1], corpus[j]);
  }
  corpus.resize(kPoolSize);
  return corpus;
}

}  // namespace polybius
