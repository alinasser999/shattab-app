import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_loading.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icon/app_icon_foreground.png',
                    width: 220,
                    height: 112,
                    fit: BoxFit.contain,
                    semanticLabel: context.l10n.appName,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.taglineNew,
                    textAlign: TextAlign.center,
                    style: BatshTypography.bodyMd.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (profile.hasError)
                    BatshError(
                      compact: true,
                      onRetry: () => ref.invalidate(currentProfileProvider),
                    )
                  else
                    const BatshLoading(size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
