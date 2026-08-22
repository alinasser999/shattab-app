import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/core/l10n/strings.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../pricing.dart';
import 'payment_flow.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_motion.dart';
import '../domain/billing_state.dart';
import 'providers/billing_providers.dart';
import '../../../core/widgets/shattab_pattern.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Shattab Pro subscription page. The one surface that earns a Committed /
/// Drenched treatment (aspirational terracotta hero) inside an otherwise
/// Restrained product. InstaPay is a manual verification flow; processor-backed
/// payment methods remain explicitly marked as pending. Message is contractor
/// ROI, not "luxury".
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  bool _annual = false;

  void _subscribe() {
    // Opens InstaPay (functional) / Apple Pay (pending processor) chooser.
    showPaymentMethods(context, annual: _annual);
  }

  void _subscribeSpecialPlacement() {
    showPaymentMethods(
      context,
      annual: false,
      purpose: 'sponsored',
      planTerm: 'weekly',
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    final billingState = ref.watch(billingStateProvider);
    final billing = billingState.asData?.value;
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(motion: motion),
            // Plan card overlaps the hero's rounded bottom edge.
            Transform.translate(
              offset: const Offset(0, -36),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.gutter,
                ),
                child: _PlanCard(
                  annual: _annual,
                  onToggle: (v) => setState(() => _annual = v),
                  onSubscribe: _subscribe,
                  motion: motion,
                  billing: billing,
                  billingLoading: billingState.isLoading,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BatshSpacing.gutter,
                0,
                BatshSpacing.gutter,
                BatshSpacing.xl,
              ),
              child: _SpecialPlacementCard(
                billing: billing,
                billingLoading: billingState.isLoading,
                onSubscribe: _subscribeSpecialPlacement,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BatshSpacing.gutter,
                0,
                BatshSpacing.gutter,
                BatshSpacing.xl,
              ),
              child: const _CompareTable(),
            ),
            const _TrustFooter(),
            const SizedBox(height: BatshSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.motion});
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPad + BatshSpacing.xs,
        bottom: BatshSpacing.xxl + BatshSpacing.md,
        left: BatshSpacing.gutter,
        right: BatshSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(BatshRadius.xxl),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ShattabPattern(
              kind: ShattabPatternKind.contour,
              color: context.colorScheme.onPrimary,
              opacity: 0.10,
              strokeWidth: 0.8,
            ),
          ),
          Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BackButton(color: context.colorScheme.onPrimary),
              ),
              const SizedBox(height: BatshSpacing.xs),
              _Medallion(motion: motion),
              const SizedBox(height: BatshSpacing.md),
              Text(
                context.l10n.proScreenTitle,
                textAlign: TextAlign.center,
                style: BatshTypography.displayMd.copyWith(
                  color: context.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: BatshSpacing.xs),
              Text(
                context.l10n.proValueLine,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyLg.copyWith(
                  color: context.colorScheme.onPrimary.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.motion});
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final seal = Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colorScheme.tertiaryContainer, // light gold
            context.colorScheme.tertiary, // deep gold
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.workspace_premium_rounded,
        size: BatshIconSize.xl,
        color: context.colorScheme.onTertiaryContainer,
      ),
    );
    if (!motion) return ExcludeSemantics(child: seal);
    return ExcludeSemantics(
      child: seal
          .animate()
          .scaleXY(
            begin: 0.85,
            end: 1,
            duration: 420.ms,
            curve: BatshMotion.easeOut,
          )
          .fadeIn(duration: 320.ms),
    );
  }
}

// ── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.annual,
    required this.onToggle,
    required this.onSubscribe,
    required this.motion,
    required this.billing,
    required this.billingLoading,
  });

  final bool annual;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSubscribe;
  final bool motion;
  final BillingState? billing;
  final bool billingLoading;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      context.l10n.proBenefitQuotes,
      context.l10n.proBenefitRequests,
      context.l10n.proBenefitRanking,
      context.l10n.proBenefitPhotos,
      context.l10n.proBenefitSeen,
    ];
    final isActive = billing?.isProActive ?? false;
    final hasPendingRequest = billing?.hasPendingProRequest ?? false;
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        boxShadow: BatshShadows.floating,
      ),
      padding: const EdgeInsets.all(BatshSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isActive) ...[
            _BillingStatusBanner(
              icon: Icons.verified_rounded,
              title: context.l10n.proActiveLine,
              message: billing?.planExpiresAt == null
                  ? context.l10n.proManageSubtitle
                  : context.l10n.proExpiresOn(
                      _formatDate(context, billing!.planExpiresAt!),
                    ),
              color: context.colorScheme.secondary,
            ),
            const SizedBox(height: BatshSpacing.md),
          ] else if (hasPendingRequest) ...[
            _BillingStatusBanner(
              icon: Icons.schedule_rounded,
              title: context.l10n.instapaySubmittedTitle,
              message: context.l10n.requestsPaymentNote,
              color: context.colorScheme.tertiary,
            ),
            const SizedBox(height: BatshSpacing.md),
          ],
          _PlanToggle(annual: annual, onToggle: onToggle),
          const SizedBox(height: BatshSpacing.lg),
          _PriceBlock(annual: annual),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.proRoiLine,
            textAlign: TextAlign.center,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          for (var i = 0; i < benefits.length; i++)
            _BenefitRow(text: benefits[i], index: i, motion: motion),
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: isActive
                ? context.l10n.proActiveLine
                : hasPendingRequest
                ? context.l10n.instapaySubmittedTitle
                : context.l10n.upgradeToProCta,
            icon: Icons.workspace_premium_outlined,
            onPressed: billingLoading || isActive || hasPendingRequest
                ? null
                : onSubscribe,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            context.l10n.cancelAnytime,
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) => DateFormat(
    'd MMM yyyy',
    Localizations.localeOf(context).languageCode,
  ).format(date);
}

class _BillingStatusBanner extends StatelessWidget {
  const _BillingStatusBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BatshRadius.brMd,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: BatshIconSize.md),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BatshTypography.labelLg),
                const SizedBox(height: BatshSpacing.xxs),
                Text(
                  message,
                  style: BatshTypography.bodySm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanToggle extends StatelessWidget {
  const _PlanToggle({required this.annual, required this.onToggle});
  final bool annual;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.xxs),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        children: [
          _seg(
            context,
            label: context.l10n.planMonthly,
            selected: !annual,
            onTap: () => onToggle(false),
          ),
          _seg(
            context,
            label: context.l10n.planAnnual,
            selected: annual,
            onTap: () => onToggle(true),
            badge: context.l10n.annualSaveBadge,
          ),
        ],
      ),
    );
  }

  Widget _seg(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: 180.ms,
            curve: BatshMotion.easeOut,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? context.colorScheme.surfaceContainerLowest
                  : Colors.transparent,
              borderRadius: BatshRadius.brFull,
              boxShadow: selected ? BatshShadows.subtle : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: BatshTypography.labelLg.copyWith(
                    color: selected
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: BatshSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.xs,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: Text(
                      badge,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.annual});
  final bool annual;

  @override
  Widget build(BuildContext context) {
    final price = annual
        ? BatshPricing.proAnnualEgp
        : BatshPricing.proMonthlyEgp;
    final unit = annual ? context.l10n.perYear : context.l10n.perMonth;
    return AnimatedSwitcher(
      duration: 200.ms,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Row(
        key: ValueKey(annual),
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _digits('$price'),
            style: BatshTypography.displayLg.copyWith(
              fontSize: 48,
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            context.l10n.egpUnit,
            style: BatshTypography.titleLg.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            unit,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.text,
    required this.index,
    required this.motion,
  });
  final String text;
  final int index;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final Widget row = Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: BatshIconSize.md,
            color: context.colorScheme.tertiary,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(child: Text(text, style: BatshTypography.bodyMd)),
        ],
      ),
    );
    if (!motion) return row;
    return row
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.08, end: 0, curve: BatshMotion.easeOut);
  }
}

// ── Free vs Pro comparison ───────────────────────────────────────────────────

class _SpecialPlacementCard extends StatelessWidget {
  const _SpecialPlacementCard({
    required this.billing,
    required this.billingLoading,
    required this.onSubscribe,
  });

  final BillingState? billing;
  final bool billingLoading;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final active = billing?.isSponsoredActive ?? false;
    final pending = billing?.hasPendingSponsoredRequest ?? false;
    final statusColor = active
        ? context.colorScheme.secondary
        : context.colorScheme.tertiary;
    final statusMessage = active && billing?.sponsoredUntil != null
        ? context.l10n.specialProExpiresOn(
            _formatDate(context, billing!.sponsoredUntil!),
          )
        : pending
        ? context.l10n.specialProPendingBody
        : context.l10n.specialProActivationNote;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brCard,
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
        boxShadow: BatshShadows.subtle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            end: 0,
            width: 150,
            height: 150,
            child: IgnorePointer(
              child: ShattabPattern(
                kind: ShattabPatternKind.arches,
                color: context.colorScheme.primary,
                opacity: 0.055,
                strokeWidth: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BatshSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colorScheme.tertiaryContainer,
                        borderRadius: BatshRadius.brMd,
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        color: context.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.l10n.specialProTitle,
                                  style: BatshTypography.titleLg.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: BatshSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BatshSpacing.xs,
                                  vertical: BatshSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.tertiaryContainer,
                                  borderRadius: BatshRadius.brFull,
                                ),
                                child: Text(
                                  context.l10n.paidPlacementLabel,
                                  style: BatshTypography.labelSm.copyWith(
                                    color:
                                        context.colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BatshSpacing.xxs),
                          Text(
                            context.l10n.specialProSubtitle,
                            style: BatshTypography.bodySm.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.md),
                Text(
                  context.l10n.specialProValueLine,
                  style: BatshTypography.bodyMd,
                ),
                const SizedBox(height: BatshSpacing.sm),
                _PlacementBenefit(
                  icon: Icons.visibility_outlined,
                  text: context.l10n.specialProBenefit,
                ),
                _PlacementBenefit(
                  icon: Icons.verified_outlined,
                  text: context.l10n.specialProFairness,
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  statusMessage,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: BatshSpacing.md),
                BatshButton(
                  label: active
                      ? context.l10n.specialProActive
                      : pending
                      ? context.l10n.specialProPending
                      : context.l10n.specialProCta,
                  icon: active
                      ? Icons.check_circle_outline_rounded
                      : pending
                      ? Icons.schedule_outlined
                      : Icons.arrow_back_rounded,
                  isLoading: billingLoading,
                  onPressed: active || pending ? null : onSubscribe,
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  '${context.l10n.specialProPriceLine} · ${context.l10n.specialProNoGuarantee}',
                  textAlign: TextAlign.center,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) => DateFormat(
    'd MMM yyyy',
    Localizations.localeOf(context).languageCode,
  ).format(date);
}

class _PlacementBenefit extends StatelessWidget {
  const _PlacementBenefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: BatshIconSize.md,
            color: context.colorScheme.tertiary,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(child: Text(text, style: BatshTypography.bodySm)),
        ],
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brLg,
      ),
      padding: const EdgeInsets.all(BatshSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.comparePlans,
            style: BatshTypography.titleMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BatshSpacing.md),
          _header(context),
          Divider(
            height: BatshSpacing.lg,
            color: context.colorScheme.outlineVariant,
          ),
          _row(
            context,
            context.l10n.cmpQuotes,
            context.l10n.cmpQuotesFree,
            context.l10n.cmpUnlimited,
          ),
          _row(
            context,
            context.l10n.cmpRequests,
            context.l10n.cmpRequestsFree,
            context.l10n.cmpRequestsPro,
          ),
          _row(
            context,
            context.l10n.cmpRanking,
            context.l10n.cmpRankingFree,
            context.l10n.cmpRankingPro,
          ),
          _row(
            context,
            context.l10n.cmpPortfolio,
            context.l10n.cmpPortfolioFree,
            context.l10n.cmpUnlimited,
          ),
          _row(context, context.l10n.cmpSeenRow, null, null),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 4, child: SizedBox()),
        Expanded(
          flex: 3,
          child: Text(
            context.l10n.freePlanName,
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            context.l10n.proPlanName,
            textAlign: TextAlign.center,
            style: BatshTypography.labelLg.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Null values render as ✕ (free) / ✓ (pro) for boolean rows.
  Widget _row(BuildContext context, String label, String? free, String? pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xs),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: BatshTypography.bodyMd)),
          Expanded(flex: 3, child: _cell(context, free, isPro: false)),
          Expanded(flex: 3, child: _cell(context, pro, isPro: true)),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String? value, {required bool isPro}) {
    if (value == null) {
      return Icon(
        isPro
            ? Icons.check_circle_rounded
            : Icons.remove_circle_outline_rounded,
        size: BatshIconSize.md,
        color: isPro
            ? context.colorScheme.tertiary
            : context.colorScheme.outlineVariant,
      );
    }
    return Text(
      value,
      textAlign: TextAlign.center,
      style: BatshTypography.labelMd.copyWith(
        color: isPro
            ? context.colorScheme.onSurface
            : context.colorScheme.onSurfaceVariant,
        fontWeight: isPro ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

// ── Trust footer ─────────────────────────────────────────────────────────────

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: BatshIconSize.sm,
          color: context.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: BatshSpacing.xs),
        Text(
          context.l10n.trustPaymob,
          style: BatshTypography.labelMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

const _arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Localize Western digits to Arabic-Indic when the app is in Arabic.
String _digits(String s) {
  if (S.egpUnit == 'EGP') return s; // English mode keeps Western digits
  return s.replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => _arDigits[int.parse(m[0]!)],
  );
}
