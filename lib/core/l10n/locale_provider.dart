import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'strings.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    unawaited(_restore());
    return const Locale('ar', 'EG');
  }

  void setLocale(Locale locale) {
    state = locale;
    S.setLanguage(locale.languageCode == 'en');
    unawaited(_persist(locale));
  }

  void toggle() {
    final next = state.languageCode == 'en'
        ? const Locale('ar', 'EG')
        : const Locale('en', 'US');
    setLocale(next);
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final language = prefs.getString('locale_language');
    if (language == 'en') {
      setLocale(const Locale('en', 'US'));
    }
  }

  Future<void> _persist(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_language', locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
