#pragma once

#include "polybius/board_ui.h"

namespace polybius {

/// Serial command shell shared by every board (USB CDC / UART).
/// Commands:
///   unlock <pin>
///   seed <text>
///   complexity <2-6>
///   enc <plaintext>
///   dec <emoji-or-paste>
///   pool
///   sync
///   import <token>
///   help
class SerialShell {
 public:
  void begin(AppState& state);
  /// Process available serial bytes; returns true if UI should redraw.
  bool poll(AppState& state);
};

}  // namespace polybius
