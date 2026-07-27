import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';

enum MotionMode { full, reduced, off }

class MotionModeNotifier extends Notifier<MotionMode> {
  @override
  MotionMode build() => MotionMode.full;

  void set(MotionMode mode) => state = mode;
  String get label => switch (state) {
    MotionMode.full => S.motionFull,
    MotionMode.reduced => S.motionReduced,
    MotionMode.off => S.motionOff,
  };
  void toggle() {
    state = switch (state) {
      MotionMode.full => MotionMode.reduced,
      MotionMode.reduced => MotionMode.off,
      MotionMode.off => MotionMode.full,
    };
  }
}

final motionModeProvider = NotifierProvider<MotionModeNotifier, MotionMode>(
  MotionModeNotifier.new,
);

/// Check system-level reduced motion preference.
extension MotionContext on BuildContext {
  bool get systemMotionReduced => MediaQuery.disableAnimationsOf(this);
}
