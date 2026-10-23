import 'package:flutter/services.dart';

class Haptics {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }
}
