import 'package:flutter/material.dart';

/// Digital stand-in for the physical red cabinet lamp.
///
/// Cyan house-light labels crush to black. Deep-red phosphor labels remain.
/// This is a demonstration filter, not a claim that a screenshot is safe.
class CabinetLamp {
  static const phosphor = Color(0xFF5A000C);
  static const houseCyan = Color(0xFF00FFFF);

  static const ColorFilter matrix = ColorFilter.matrix(<double>[
    1.15, 0, 0, 0, 18,
    0, 0.04, 0, 0, 0,
    0, 0, 0.04, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  static Widget wrap({required bool on, required Widget child}) {
    if (!on) return child;
    return ColorFiltered(colorFilter: matrix, child: child);
  }
}
