import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'strings.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar', 'EG');

  void setLocale(Locale locale) {
    state = locale;
    S.setLanguage(locale.languageCode == 'en');
  }

  void toggle() {
    final next =
        state.languageCode == 'en' ? const Locale('ar', 'EG') : const Locale('en', 'US');
    setLocale(next);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
