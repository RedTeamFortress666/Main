#include "polybius/cipher_engine.h"
#include "polybius/daily_pool.h"
#include "polybius/dart_compat.h"
#include "polybius/pool_sync.h"
#include "polybius/rotor.h"
#include "polybius/sha256.h"
#include "polybius/utf8_util.h"

#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static int gFails = 0;

#define EXPECT_EQ(a, b)                                                        \
  do {                                                                         \
    const auto _a = (a);                                                       \
    const auto _b = (b);                                                       \
    if ((_a) != (_b)) {                                                        \
      std::fprintf(stderr, "FAIL %s:%d: %s != %s\n", __FILE__, __LINE__, #a,   \
                   #b);                                                        \
      ++gFails;                                                                \
    }                                                                          \
  } while (0)

#define EXPECT_TRUE(x)                                                         \
  do {                                                                         \
    if (!(x)) {                                                                \
      std::fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #x);        \
      ++gFails;                                                                \
    }                                                                          \
  } while (0)

int main() {
  // Dart String.hashCode
  EXPECT_EQ(polybius::dartStringHash(""), 1u);
  EXPECT_EQ(polybius::dartStringHash("a"), 170824770u);
  EXPECT_EQ(polybius::dartStringHash("ab"), 98967128u);
  EXPECT_EQ(polybius::dartStringHash("2026-07-22"), 529522096u);

  // Dart Random(42).nextInt(280) x10
  {
    polybius::DartRandom rng(42);
    const int expect[] = {27, 78, 124, 165, 237, 24, 15, 85, 80, 168};
    for (int v : expect) EXPECT_EQ(rng.nextInt(280), v);
  }

  // Daily pool golden vectors from Flutter
  {
    const auto pool = polybius::DailyPool::generate("2026-07-22");
    EXPECT_EQ(static_cast<int>(pool.size()), 560);
    EXPECT_EQ(pool[0], 128032u);   // 🐠
    EXPECT_EQ(pool[1], 128144u);   // 💐
    EXPECT_EQ(pool[279], 10134u);  // ➖ U+2796 = 10134? Wait check
    // Golden: POOL279 ➖ → codepoint
    EXPECT_EQ(pool[279], static_cast<uint32_t>(U'➖'));
    EXPECT_EQ(pool[280], static_cast<uint32_t>(U'🐋'));
    EXPECT_EQ(pool[559], static_cast<uint32_t>(U'👭'));

    const auto head = std::vector<uint32_t>(
        {128032, 128144, 127945, 129717, 129383, 127850, 129399, 129321,
         128066, 129470, 128590, 128251, 128672, 129435, 128105, 129299,
         128702, 127978, 128570, 128162});
    for (size_t i = 0; i < head.size(); ++i) EXPECT_EQ(pool[i], head[i]);

    EXPECT_EQ(polybius::PoolSync::poolIdFor("2026-07-22"),
              std::string("3A1DC5BFE2D5"));
    EXPECT_EQ(polybius::PoolSync::poolHashFor("2026-07-22"),
              std::string("acbf1257443671a2"));
  }

  // Rotor I wiring
  {
    auto r = polybius::Rotor::create("I", "2026-07-22", 0);
    EXPECT_EQ(r.notch(), 50);
    EXPECT_EQ(r.wiring()[0], 77);
    EXPECT_EQ(r.wiring()[1], 234);
    EXPECT_EQ(r.wiring()[100], 275);
  }

  // Encrypt / decrypt HELLO
  {
    polybius::CipherEngine eng("2026-07-22", 2);
    const std::string enc = eng.encrypt("HELLO");
    const auto cps = polybius::utf8ToCodepoints(enc);
    const std::vector<uint32_t> expect = {128542, 128656, 128686, 128212, 128104,
                                          9193,   128153, 9193,   9196,   129747};
    EXPECT_EQ(cps.size(), expect.size());
    for (size_t i = 0; i < expect.size() && i < cps.size(); ++i) {
      EXPECT_EQ(cps[i], expect[i]);
    }
    EXPECT_EQ(polybius::CipherEngine("2026-07-22").decrypt(enc),
              std::string("HELLO"));
  }

  // Complexity 3
  {
    polybius::CipherEngine eng("complexity-seed", 3);
    const auto cps = polybius::utf8ToCodepoints(eng.encrypt("AB"));
    const std::vector<uint32_t> expect = {127832, 129393, 128175,
                                          129432, 128011, 127984};
    EXPECT_EQ(cps.size(), expect.size());
    for (size_t i = 0; i < expect.size() && i < cps.size(); ++i) {
      EXPECT_EQ(cps[i], expect[i]);
    }
  }

  // Round-trip
  {
    polybius::CipherEngine eng("2026-07-22");
    const char* plain = "Hello World 123!";
    const std::string enc = eng.encrypt(plain);
    EXPECT_EQ(eng.decrypt(enc), std::string(plain));
  }

  if (gFails) {
    std::fprintf(stderr, "%d assertion(s) failed\n", gFails);
    return 1;
  }
  std::puts("All host cipher tests passed.");
  return 0;
}
