import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    unawaited(_restore());
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(_persist(mode));
  }

  void toggle() {
    final resolved = state == ThemeMode.system
        ? WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light
        : state;
    setThemeMode(resolved == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = switch (prefs.getString('theme_mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
