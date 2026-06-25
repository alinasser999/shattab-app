import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_loading.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return BatshScaffold(
      title: S.tabProfile,
      body: profileAsync.when(
        loading: () => const BatshLoading(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          return ListView(
            children: [
              const SizedBox(height: BatshSpacing.md),
              BatshCard(
                padding: const EdgeInsets.all(BatshSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: BatshTypography.titleLg),
                    const SizedBox(height: BatshSpacing.xs),
                    Text(
                      profile.phone,
                      style: BatshTypography.bodyMd
                          .copyWith(color: BatshColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (profile.role == UserRole.contractor) ...[
                const SizedBox(height: BatshSpacing.gutter),
                _ContractorBlock(),
              ],
              const SizedBox(height: BatshSpacing.xl),
              BatshButton(
                label: S.signOut,
                style: BatshButtonStyle.secondary,
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContractorBlock extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCo = ref.watch(contractorProfileProvider);
    return asyncCo.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (co) {
        if (co == null) return const SizedBox.shrink();
        return BatshCard(
          padding: const EdgeInsets.all(BatshSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(co.businessName ?? '', style: BatshTypography.titleLg),
              if (co.bio != null && co.bio!.isNotEmpty) ...[
                const SizedBox(height: BatshSpacing.sm),
                Text(co.bio!, style: BatshTypography.bodyMd),
              ],
              if (co.yearsExperience != null) ...[
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  '${co.yearsExperience} سنين خبرة',
                  style: BatshTypography.labelMd
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
