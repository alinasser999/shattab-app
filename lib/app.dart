import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/locale_provider.dart';
import 'core/l10n/strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/batsh_theme.dart';
import 'core/theme/motion_mode_provider.dart';
import 'core/theme/theme_mode_provider.dart';

class BatshApp extends ConsumerWidget {
  const BatshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final motionMode = ref.watch(motionModeProvider);

    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: BatshTheme.light(),
      darkTheme: BatshTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Every `MediaQuery.of(context).disableAnimations` check throughout
        // the app (the codebase's reduced-motion gate) only ever reflected
        // the OS accessibility setting — the in-app Motion toggle in
        // Profile changed its own label but never touched real animations.
        // OR it in here so both sources actually disable motion.
        if (child == null) return const SizedBox.shrink();
        if (motionMode == MotionMode.full) return child;
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(disableAnimations: true),
          child: child,
        );
      },
    );
  }
}
