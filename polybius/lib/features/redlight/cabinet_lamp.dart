import 'package:flutter/material.dart';

/// Digital stand-in for the physical red cabinet lamp.
///
/// Cyan house-light labels crush to black. Deep-red phosphor labels remain.
/// This is a demonstration filter, not a claim that a screenshot is safe.
///
/// The live matrix comes from the operator's sealed [RedlightProfile]; the
/// constant below is only the house default used when no vault is open —
/// and in that case the lamp does not switch on at all.
class CabinetLamp {
  static const phosphor = Color(0xFF5A000C);
  static const houseCyan = Color(0xFF00FFFF);

  static const ColorFilter matrix = ColorFilter.matrix(<double>[
    1.35, 0, 0, 0, 28,
    0, 0.03, 0, 0, 0,
    0, 0, 0.03, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  static Widget wrap({
    required bool on,
    required Widget child,
    ColorFilter? filter,
  }) {
    if (!on) return child;
    return ColorFiltered(colorFilter: filter ?? matrix, child: child);
  }
}
