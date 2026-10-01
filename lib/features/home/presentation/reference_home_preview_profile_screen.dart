import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/avatar_with_initials.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/shattab_pattern.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../domain/reference_home_data.dart';

/// A local-only profile destination for the screenshot inspection build.
///
/// Reference cards use presentation fixtures when the explicit preview define
/// is enabled. They still need a real destination so visual QA can exercise
/// the same tap path as a live professional card. This screen deliberately
/// keeps the fixture boundary visible and sends its primary action into the
/// real homeowner request flow.
class ReferenceHomePreviewProfileScreen extends ConsumerWidget {
  const ReferenceHomePreviewProfileScreen({
    super.key,
    required this.professionalId,
  });

  final String professionalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professional = ReferenceHomePreviewData.professionalForId(
      professionalId,
    );

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.055,
                child: ShattabPattern(
                  kind: ShattabPatternKind.arches,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _PreviewProfileToolbar(onBack: () => context.pop()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.pageGutter,
                      BatshSpacing.xs,
                      BatshSpacing.pageGutter,
                      0,
                    ),
                    child: _ProfileIdentity(professional: professional),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.pageGutter,
                      BatshSpacing.md,
                      BatshSpacing.pageGutter,
                      0,
                    ),
                    child: _ProfileStats(professional: professional),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.pageGutter,
                      BatshSpacing.md,
                      BatshSpacing.pageGutter,
                      0,
                    ),
                    child: _ProfileSection(
                      title: 'عن المحترف',
                      child: Text(
                        'خبرة عملية في ${professional.specialty}، مع اهتمام بالتفاصيل وتنسيق خطوات التنفيذ من البداية للنهاية.',
                        textAlign: TextAlign.right,
                        style: BatshTypography.bodyMd.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          height: 1.65,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.pageGutter,
                      BatshSpacing.md,
                      BatshSpacing.pageGutter,
                      0,
                    ),
                    child: _ProfileSection(
                      title: 'نماذج من الشغل',
                      child: ClipRRect(
                        borderRadius: BatshRadius.brCard,
                        child: AspectRatio(
                          aspectRatio: 1.78,
                          child: Image.asset(
                            ReferenceHomePreviewData.beforeAfterImage,
                            fit: BoxFit.cover,
                            semanticLabel: 'نماذج قبل وبعد من أعمال المحترف',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.pageGutter,
                      BatshSpacing.md,
                      BatshSpacing.pageGutter,
                      0,
                    ),
                    child: _ProfileSection(
                      title: 'الخدمات',
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: BatshSpacing.xs,
                        runSpacing: BatshSpacing.xs,
                        children:
                            [
                                  professional.specialty,
                                  'تنفيذ وتسليم',
                                  'معاينة المشروع',
                                ]
                                .map(
                                  (label) => Chip(
                                    label: Text(label),
                                    labelStyle: BatshTypography.labelMd
                                        .copyWith(
                                          color: context.colorScheme.primary,
                                        ),
                                    backgroundColor:
                                        context.colorScheme.primaryContainer,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BatshRadius.brFull,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 132)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.surface.withValues(alpha: 0.96),
                  boxShadow: BatshShadows.soft,
                  border: Border(
                    top: BorderSide(
                      color: context.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BatshSpacing.pageGutter,
                    BatshSpacing.sm,
                    BatshSpacing.pageGutter,
                    BatshSpacing.sm,
                  ),
                  child: BatshButton(
                    label: 'اطلب عرض من المحترف',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => runSignedIn(
                      context,
                      ref,
                      reason: 'سجّل دخولك لطلب عرض من هذا المحترف',
                      action: () => context.push(Routes.homeownerNewPost),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewProfileToolbar extends StatelessWidget {
  const _PreviewProfileToolbar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.xs,
        vertical: BatshSpacing.xxs,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'رجوع',
            child: IconButton(
              onPressed: onBack,
              tooltip: 'رجوع',
              icon: const Icon(Icons.arrow_forward_rounded),
              iconSize: BatshIconSize.action,
            ),
          ),
          Expanded(
            child: Text(
              'ملف المحترف',
              textAlign: TextAlign.center,
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: BatshSpacing.minHitArea),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.professional});

  final ReferenceHomeProfessional professional;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWithInitials(
            imageUrl: professional.avatarUrl,
            name: professional.name,
            radius: 34,
          ),
          const SizedBox(width: BatshSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  professional.name,
                  textAlign: TextAlign.right,
                  style: BatshTypography.titleLg.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Text(
                  professional.specialty,
                  textAlign: TextAlign.right,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: BatshIconSize.inline,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: BatshSpacing.xxs),
                    Flexible(
                      child: Text(
                        professional.location,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (professional.verified) ...[
                  const SizedBox(height: BatshSpacing.xs),
                  _VerifiedPill(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        borderRadius: BatshRadius.brFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: BatshIconSize.inline,
              color: context.colorScheme.secondary,
            ),
            const SizedBox(width: BatshSpacing.xxs),
            Text(
              'موثق من شطب',
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.professional});

  final ReferenceHomeProfessional professional;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.sm),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _Stat(
            value: professional.rating.toStringAsFixed(1),
            label: 'التقييم',
            icon: Icons.star_rounded,
            color: BatshColors.starGold,
          ),
          _Stat(
            value: '${professional.reviewCount}',
            label: 'تقييم',
            icon: Icons.rate_review_outlined,
            color: context.colorScheme.primary,
          ),
          _Stat(
            value: '${professional.projectsCompleted}',
            label: 'مشروع مكتمل',
            icon: Icons.work_outline_rounded,
            color: context.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: BatshIconSize.md),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            value,
            style: BatshTypography.titleMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: BatshTypography.titleMd.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: BatshSpacing.sm),
        child,
      ],
    );
  }
}
