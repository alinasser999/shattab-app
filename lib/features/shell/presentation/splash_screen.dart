import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BatshColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.appName,
              style: BatshTypography.displayLg
                  .copyWith(color: BatshColors.primary),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: BatshColors.primary),
          ],
        ),
      ),
    );
  }
}
