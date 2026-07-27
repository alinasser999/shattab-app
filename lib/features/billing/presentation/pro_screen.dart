import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../pricing.dart';
import 'payment_flow.dart';
import '../../../core/theme/batsh_icon_size.dart';

/// Shattab Pro subscription page. The one surface that earns a Committed /
/// Drenched treatment (aspirational terracotta hero) inside an otherwise
/// Restrained product. Presentational: the CTA is inert until Paymob is wired
/// (Phase 3). Message is contractor ROI, not "luxury".
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _annual = false;

  void _subscribe() {
    // Opens InstaPay (functional) / Apple Pay (pending processor) chooser.
    showPaymentMethods(context, annual: _annual);
  }

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: BatshColors.surface,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BatshColors.primary,
            BatshColors.onPrimaryFixedVariant, // deep terracotta
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(BatshRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: BackButton(color: BatshColors.onPrimary),
          ),
          const SizedBox(height: BatshSpacing.xs),
          _Medallion(motion: motion),
          const SizedBox(height: BatshSpacing.md),
          Text(
            S.proScreenTitle,
            textAlign: TextAlign.center,
            style: BatshTypography.displayMd.copyWith(
              color: BatshColors.onPrimary,
            ),
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            S.proValueLine,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyLg.copyWith(
              color: BatshColors.onPrimary.withValues(alpha: 0.88),
            ),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BatshColors.tertiaryContainer, // light gold
            BatshColors.tertiary, // deep gold
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BatshColors.tertiaryContainer.withValues(alpha: 0.5),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        size: BatshIconSize.xl,
        color: BatshColors.onTertiaryContainer,
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
            curve: Curves.easeOutCubic,
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
  });

  final bool annual;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSubscribe;
  final bool motion;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      S.proBenefitQuotes,
      S.proBenefitRequests,
      S.proBenefitRanking,
      S.proBenefitPhotos,
      S.proBenefitSeen,
    ];
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        boxShadow: BatshShadows.floating,
      ),
      padding: const EdgeInsets.all(BatshSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanToggle(annual: annual, onToggle: onToggle),
          const SizedBox(height: BatshSpacing.lg),
          _PriceBlock(annual: annual),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            S.proRoiLine,
            textAlign: TextAlign.center,
            style: BatshTypography.bodySm.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          for (var i = 0; i < benefits.length; i++)
            _BenefitRow(text: benefits[i], index: i, motion: motion),
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: S.startFreeMonth,
            icon: Icons.workspace_premium_outlined,
            onPressed: onSubscribe,
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            S.cancelAnytime,
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd.copyWith(
              color: BatshColors.onSurfaceVariant,
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
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        children: [
          _seg(
            label: S.planMonthly,
            selected: !annual,
            onTap: () => onToggle(false),
          ),
          _seg(
            label: S.planAnnual,
            selected: annual,
            onTap: () => onToggle(true),
            badge: S.annualSaveBadge,
          ),
        ],
      ),
    );
  }

  Widget _seg({
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
            curve: Curves.easeOut,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? BatshColors.surfaceContainerLowest
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
                        ? BatshColors.primary
                        : BatshColors.onSurfaceVariant,
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
                      color: BatshColors.secondaryContainer,
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: Text(
                      badge,
                      style: BatshTypography.labelSm.copyWith(
                        color: BatshColors.onSecondaryContainer,
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
    final unit = annual ? S.perYear : S.perMonth;
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
              color: BatshColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            S.egpUnit,
            style: BatshTypography.titleLg.copyWith(color: BatshColors.primary),
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            unit,
            style: BatshTypography.bodyMd.copyWith(
              color: BatshColors.onSurfaceVariant,
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
          const Icon(
            Icons.check_circle_rounded,
            size: BatshIconSize.md,
            color: BatshColors.tertiary,
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
        .slideX(begin: 0.08, end: 0, curve: Curves.easeOut);
  }
}

// ── Free vs Pro comparison ───────────────────────────────────────────────────

class _CompareTable extends StatelessWidget {
  const _CompareTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brLg,
      ),
      padding: const EdgeInsets.all(BatshSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.comparePlans,
            style: BatshTypography.titleMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BatshSpacing.md),
          _header(),
          const Divider(height: BatshSpacing.lg, color: BatshColors.divider),
          _row(S.cmpQuotes, S.cmpQuotesFree, S.cmpUnlimited),
          _row(S.cmpRequests, S.cmpRequestsFree, S.cmpRequestsPro),
          _row(S.cmpRanking, S.cmpRankingFree, S.cmpRankingPro),
          _row(S.cmpPortfolio, S.cmpPortfolioFree, S.cmpUnlimited),
          _row(S.cmpSeenRow, null, null),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(flex: 4, child: SizedBox()),
        Expanded(
          flex: 3,
          child: Text(
            S.freePlanName,
            textAlign: TextAlign.center,
            style: BatshTypography.labelMd.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            S.proPlanName,
            textAlign: TextAlign.center,
            style: BatshTypography.labelLg.copyWith(color: BatshColors.primary),
          ),
        ),
      ],
    );
  }

  /// Null values render as ✕ (free) / ✓ (pro) for boolean rows.
  Widget _row(String label, String? free, String? pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xs),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: BatshTypography.bodyMd)),
          Expanded(flex: 3, child: _cell(free, isPro: false)),
          Expanded(flex: 3, child: _cell(pro, isPro: true)),
        ],
      ),
    );
  }

  Widget _cell(String? value, {required bool isPro}) {
    if (value == null) {
      return Icon(
        isPro
            ? Icons.check_circle_rounded
            : Icons.remove_circle_outline_rounded,
        size: BatshIconSize.md,
        color: isPro ? BatshColors.tertiary : BatshColors.outlineVariant,
      );
    }
    return Text(
      value,
      textAlign: TextAlign.center,
      style: BatshTypography.labelMd.copyWith(
        color: isPro ? BatshColors.onSurface : BatshColors.onSurfaceVariant,
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
        const Icon(
          Icons.lock_outline_rounded,
          size: BatshIconSize.sm,
          color: BatshColors.onSurfaceVariant,
        ),
        const SizedBox(width: BatshSpacing.xs),
        Text(
          S.trustPaymob,
          style: BatshTypography.labelMd.copyWith(
            color: BatshColors.onSurfaceVariant,
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
