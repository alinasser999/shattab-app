import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';

class BriefDetailScreen extends ConsumerWidget {
  const BriefDetailScreen({super.key, required this.briefId});

  final String briefId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء الطلب؟'),
        content: const Text('مش هيقدر يتفعّل تاني بعد ما تلغيه.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('لأ، خليه')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('أيوة، إلغي')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(briefsControllerProvider.notifier).cancel(briefId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(briefByIdProvider(briefId));

    return BatshScaffold(
      title: 'تفاصيل الطلب',
      body: async.when(
        loading: () => const BatshLoading(),
        error: (e, _) => BatshError(message: e.toString()),
        data: (brief) {
          if (brief == null) {
            return const BatshError(message: 'الطلب مش موجود');
          }
          final date = intl.DateFormat.yMMMd('ar').format(brief.createdAt);
          return ListView(
            children: [
              const SizedBox(height: BatshSpacing.md),
              _StatusRow(brief: brief, date: date),
              const SizedBox(height: BatshSpacing.lg),
              if (brief.photoUrls.isNotEmpty) ...[
                PhotoGallery(urls: brief.photoUrls),
                const SizedBox(height: BatshSpacing.lg),
              ],
              BatshCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('وصف الشغل',
                        style: BatshTypography.labelMd.copyWith(
                            color: BatshColors.onSurfaceVariant)),
                    const SizedBox(height: BatshSpacing.sm),
                    Text(brief.workDescription,
                        style: BatshTypography.bodyLg),
                  ],
                ),
              ),
              const SizedBox(height: BatshSpacing.gutter),
              BatshCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تفاصيل المكان',
                        style: BatshTypography.labelMd.copyWith(
                            color: BatshColors.onSurfaceVariant)),
                    const SizedBox(height: BatshSpacing.sm),
                    Text(
                      '${OnboardingCatalog.apartmentLabels[brief.apartmentType] ?? brief.apartmentType.name} · ${brief.city}${brief.district != null ? ' · ${brief.district}' : ''}',
                      style: BatshTypography.bodyLg,
                    ),
                  ],
                ),
              ),
              if (brief.isPost && brief.targetSpecialties.isNotEmpty) ...[
                const SizedBox(height: BatshSpacing.gutter),
                BatshCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بدور على',
                          style: BatshTypography.labelMd.copyWith(
                              color: BatshColors.onSurfaceVariant)),
                      const SizedBox(height: BatshSpacing.sm),
                      Wrap(
                        spacing: BatshSpacing.xs,
                        runSpacing: BatshSpacing.xs,
                        children: brief.targetSpecialties
                            .map((s) => Text(
                                OnboardingCatalog.specialtiesCatalog[s] ?? s,
                                style: BatshTypography.bodyMd))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: BatshSpacing.xl),
              if (brief.status == BriefStatus.open)
                BatshButton(
                  label: 'إلغاء الطلب',
                  style: BatshButtonStyle.secondary,
                  onPressed: () async {
                    await _cancel(context, ref);
                    if (context.mounted) context.pop();
                  },
                ),
              const SizedBox(height: BatshSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.brief, required this.date});
  final Brief brief;
  final String date;
  @override
  Widget build(BuildContext context) {
    final isPost = brief.isPost;
    final isCancelled = brief.status == BriefStatus.cancelled;
    final color = isCancelled
        ? BatshColors.onSurfaceVariant
        : (isPost ? BatshColors.tertiary : BatshColors.primary);
    final label = isCancelled
        ? 'ملغي'
        : (isPost ? 'بوست عام' : 'طلب مباشر');
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: BatshSpacing.sm),
        Text(label,
            style: BatshTypography.labelMd
                .copyWith(color: color, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(date,
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant)),
      ],
    );
  }
}
