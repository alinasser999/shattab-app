import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';

class BriefSentScreen extends ConsumerWidget {
  const BriefSentScreen({super.key, required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractor =
        ref.watch(contractorByIdProvider(contractorId)).value;

    return BatshScaffold(
      showAppBar: false,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(BatshSpacing.gutter),
              decoration: const BoxDecoration(
                color: BatshColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 56, color: BatshColors.primary),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(
              'تم إرسال طلبك!',
              textAlign: TextAlign.center,
              style: BatshTypography.headlineMd,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              'المقاول استلم تفاصيل مشروعك وهيتواصل معاك قريب.\nتقدر تكلّمه دلوقتي على واتساب لو حابب تستعجل.',
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
            const SizedBox(height: BatshSpacing.xl),
            if (contractor != null) ...[
              WhatsAppButton(
                phone: contractor.phone,
                message: 'السلام عليكم، أنا بعتلك طلب على شطب',
              ),
              const SizedBox(height: BatshSpacing.sm),
            ],
            BatshButton(
              label: 'تمام، رجوع للاكتشاف',
              style: BatshButtonStyle.secondary,
              onPressed: () => context.go('/h/discover'),
            ),
          ],
        ),
      ),
    );
  }
}
