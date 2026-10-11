import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/locale_provider.dart';
import 'core/notifications/push_registrar.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/batsh_theme.dart';
import 'core/theme/motion_mode_provider.dart';
import 'core/theme/theme_mode_provider.dart';

class BatshApp extends ConsumerWidget {
  const BatshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Watched for its lifetime, not its value: this is where the device's push
    // token starts following the signed-in account. Nothing below reads it.
    ref.watch(pushRegistrarProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final motionMode = ref.watch(motionModeProvider);

    return MaterialApp.router(
      // `title` builds in this widget's own context, above MaterialApp in the
      // tree — no Localizations ancestor exists there yet, so context.l10n
      // null-checked and crashed on every boot. onGenerateTitle's context is
      // inside the tree MaterialApp itself creates.
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: BatshTheme.light(),
      darkTheme: BatshTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar', 'EG'), Locale('ar'), Locale('en')],
      // The hand-rolled version of this list was missing AppLocalizations
      // itself — every context.l10n call in the app was one delegate short.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        Widget result = child;
        if (motionMode != MotionMode.full) {
          final mq = MediaQuery.of(context);
          result = MediaQuery(
            data: mq.copyWith(disableAnimations: true),
            child: result,
          );
        }
        return result;
      },
    );
  }
}
