import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/debug/debug_config.dart';
import 'core/l10n/locale_provider.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_provider.dart';
import 'core/theme/batsh_theme.dart';
import 'core/theme/motion_mode_provider.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/domain/profile.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/theme/batsh_colors.dart';
import 'core/theme/batsh_radius.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshApp extends ConsumerWidget {
  const BatshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
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
        // Honour the system font size, but cap it. Many surfaces still use
        // fixed heights (search bars, CTA rows, stat tiles), so at 200% scale
        // text clips instead of reflowing. 1.5x is a compromise: the large-text
        // users this matters most for get most of their preference, and nothing
        // shears off. Drop the cap once those fixed heights become min-heights.
        Widget result = MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: child,
        );
        if (motionMode != MotionMode.full) {
          final mq = MediaQuery.of(context);
          result = MediaQuery(
            data: mq.copyWith(disableAnimations: true),
            child: result,
          );
        }
        if (kDebugAuth) {
          result = Stack(
            children: [
              result,
              const Positioned(
                top: 0,
                right: 0,
                child: SafeArea(child: _DebugBanner()),
              ),
            ],
          );
        }
        return result;
      },
    );
  }
}

// Debug-only role switcher — tree-shaken in release (kDebugAuth = kDebugMode).
class _DebugBanner extends ConsumerWidget {
  const _DebugBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role =
        ref.watch(currentProfileProvider).value?.role ?? UserRole.contractor;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BatshRadius.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔧', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            _roleBtn(context, ref, 'مالك', UserRole.homeowner, role),
            const SizedBox(width: 4),
            _roleBtn(context, ref, 'مقاول', UserRole.contractor, role),
          ],
        ),
      ),
    );
  }

  Widget _roleBtn(
    BuildContext context,
    WidgetRef ref,
    String label,
    UserRole r,
    UserRole current,
  ) {
    final active = r == current;
    return GestureDetector(
      onTap: active
          ? null
          : () async {
              await debugSwitchRole(ref.read(supabaseClientProvider), r);
              await ref.read(currentProfileProvider.notifier).refresh();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: active ? context.colorScheme.primary : Colors.white24,
          borderRadius: BatshRadius.brXs,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontFamily: 'sans-serif',
          ),
        ),
      ),
    );
  }
}
