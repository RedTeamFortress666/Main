# Host-side golden tests (no ESP32 required)
# Force native toolchain — cloud agents may inject an arm64 sysroot into CXXFLAGS.
CXX := /usr/bin/g++
CXXFLAGS := -std=c++17 -O2 -Wall -Wextra -DPOLYBIUS_HOST_TEST -Iinclude
LDFLAGS := -lcrypto

SRC = \
  src/cipher/sha256.cpp \
  src/cipher/daily_pool.cpp \
  src/cipher/rotor.cpp \
  src/cipher/cipher_engine.cpp \
  src/cipher/pool_sync.cpp

.PHONY: test clean

test: build/test_host_cipher
	./build/test_host_cipher

build/test_host_cipher: test/test_host_cipher.cpp $(SRC)
	mkdir -p build
	$(CXX) $(CXXFLAGS) -o $@ test/test_host_cipher.cpp $(SRC) $(LDFLAGS)

clean:
	rm -rf build
