import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';

enum MotionMode { full, reduced, off }

class MotionModeNotifier extends Notifier<MotionMode> {
  @override
  MotionMode build() {
    unawaited(_restore());
    return MotionMode.full;
  }

  void set(MotionMode mode) {
    state = mode;
    unawaited(_persist(mode));
  }

  String get label => switch (state) {
    MotionMode.full => S.motionFull,
    MotionMode.reduced => S.motionReduced,
    MotionMode.off => S.motionOff,
  };
  void toggle() {
    set(switch (state) {
      MotionMode.full => MotionMode.reduced,
      MotionMode.reduced => MotionMode.off,
      MotionMode.off => MotionMode.full,
    });
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final saved = prefs.getString('motion_mode');
    state = switch (saved) {
      'reduced' => MotionMode.reduced,
      'off' => MotionMode.off,
      _ => MotionMode.full,
    };
  }

  Future<void> _persist(MotionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('motion_mode', mode.name);
  }
}

final motionModeProvider = NotifierProvider<MotionModeNotifier, MotionMode>(
  MotionModeNotifier.new,
);

/// Check system-level reduced motion preference.
extension MotionContext on BuildContext {
  bool get systemMotionReduced => MediaQuery.disableAnimationsOf(this);
}
