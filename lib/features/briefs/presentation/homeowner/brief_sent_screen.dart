import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_success_checkmark.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';

class BriefSentScreen extends ConsumerWidget {
  const BriefSentScreen({super.key, required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractor = ref.watch(contractorByIdProvider(contractorId)).value;

    final reduced = MediaQuery.disableAnimationsOf(context);
    final items = <Widget>[
      const SizedBox(height: BatshSpacing.md),
      BatshSuccessCheckmark(size: 64, message: S.briefSentTitle),
      const SizedBox(height: BatshSpacing.sm),
      Text(
        S.briefSentMessageNew,
        textAlign: TextAlign.center,
        style: BatshTypography.bodyMd.copyWith(
          color: BatshColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      if (contractor != null) ...[
        WhatsAppButton(
          phone: contractor.phone,
          message: S.whatsappBriefGreeting,
        ),
        const SizedBox(height: BatshSpacing.sm),
      ],
      BatshButton(
        label: S.doneBackToDiscover,
        style: BatshButtonStyle.secondary,
        onPressed: () => context.go(Routes.homeownerDiscover),
      ),
    ];
    return BatshScaffold(
      showAppBar: false,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: reduced
              ? items
              : items
                    .animate(interval: BatshMotion.staggerBase)
                    .fadeIn(duration: BatshMotion.normal)
                    .slideY(begin: 0.08, end: 0, curve: BatshMotion.easeOut),
        ),
      ),
    );
  }
}
