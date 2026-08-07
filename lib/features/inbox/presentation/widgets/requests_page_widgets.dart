import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../billing/pricing.dart';
import '../../../briefs/domain/brief.dart';
import '../../../onboarding/domain/onboarding_models.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// The requests surface uses the same architectural language as the rest of
/// Shattab, but keeps the linework quiet enough that the request stays primary.
class RequestsPatternBackground extends StatelessWidget {
  const RequestsPatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RequestsPatternPainter(
        lineColor: context.colorScheme.outlineVariant.withValues(alpha: 0.42),
      ),
      child: child,
    );
  }
}

class _RequestsPatternPainter extends CustomPainter {
  const _RequestsPatternPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final step = 72.0;
    for (var x = -step; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 44.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final arch = Path()
      ..moveTo(size.width * 0.08, size.height * 0.22)
      ..lineTo(size.width * 0.08, size.height * 0.13)
      ..quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.06,
        size.width * 0.16,
        size.height * 0.06,
      )
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.06,
        size.width * 0.24,
        size.height * 0.13,
      )
      ..lineTo(size.width * 0.24, size.height * 0.22);
    canvas.drawPath(arch, paint);

    final roof = Path()
      ..moveTo(size.width * 0.68, size.height * 0.78)
      ..lineTo(size.width * 0.82, size.height * 0.68)
      ..lineTo(size.width * 0.96, size.height * 0.78)
      ..moveTo(size.width * 0.75, size.height * 0.73)
      ..lineTo(size.width * 0.75, size.height * 0.86)
      ..lineTo(size.width * 0.89, size.height * 0.86)
      ..lineTo(size.width * 0.89, size.height * 0.73);
    canvas.drawPath(roof, paint);

    for (final center in <Offset>[
      Offset(size.width * 0.08, size.height * 0.46),
      Offset(size.width * 0.9, size.height * 0.37),
      Offset(size.width * 0.18, size.height * 0.86),
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 28, height: 28),
        paint,
      );
      canvas.drawLine(center.translate(-14, 0), center.translate(14, 0), paint);
      canvas.drawLine(center.translate(0, -14), center.translate(0, 14), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RequestsPatternPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class RequestsUsageBanner extends StatelessWidget {
  const RequestsUsageBanner({
    super.key,
    this.used,
    this.quota,
    this.isPro = false,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  final int? used;
  final int? quota;
  final bool isPro;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? const _UsageSkeleton()
        : hasError
        ? _UsageError(onRetry: onRetry)
        : Row(
            children: [
              _UsageIcon(
                icon: isPro ? Icons.verified_rounded : Icons.check_rounded,
              ),
              const SizedBox(width: BatshSpacing.md),
              Expanded(
                child: Text(
                  isPro
                      ? context.l10n.requestsProStatus
                      : context.l10n.requestsUsage(
                          _digits(context, used ?? 0),
                          _digits(context, quota ?? 0),
                        ),
                  textAlign: TextAlign.center,
                  style: BatshTypography.bodyLg.copyWith(
                    color: isPro
                        ? context.colorScheme.success
                        : context.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      container: true,
      liveRegion: hasError,
      label: isPro
          ? context.l10n.requestsProStatus
          : context.l10n.requestsUsage(
              _digits(context, used ?? 0),
              _digits(context, quota ?? 0),
            ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.md,
          vertical: BatshSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest.withValues(
            alpha: 0.92,
          ),
          borderRadius: BatshRadius.brXxl,
          border: Border.all(
            color: context.colorScheme.outline.withValues(alpha: 0.38),
          ),
          boxShadow: BatshShadows.subtle,
        ),
        child: content,
      ),
    );
  }
}

class _UsageIcon extends StatelessWidget {
  const _UsageIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: context.colorScheme.onSecondary, size: 28),
    );
  }
}

class _UsageSkeleton extends StatelessWidget {
  const _UsageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BatshColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: BatshSpacing.md),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              height: 18,
              width: 220,
              decoration: const BoxDecoration(
                color: BatshColors.surfaceContainerHigh,
                borderRadius: BatshRadius.brSm,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UsageError extends StatelessWidget {
  const _UsageError({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UsageIcon(icon: Icons.sync_problem_rounded),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.requestsPlanRefreshError,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (onRetry != null)
          IconButton(
            tooltip: context.l10n.requestsPlanRetry,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    );
  }
}

class LockedRequestCard extends StatelessWidget {
  const LockedRequestCard({
    super.key,
    required this.request,
    required this.locked,
    required this.onTap,
  });

  final Brief request;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final apartment =
        OnboardingCatalog.apartmentLabels[request.apartmentType] ??
        request.apartmentType.name;
    final location = request.district == null
        ? '$apartment — ${request.city}'
        : '$apartment — ${request.city} — ${request.district}';
    final date = intl.DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(request.createdAt);
    final title = request.workDescription.trim().isEmpty
        ? location
        : request.workDescription.trim();

    return Semantics(
      button: true,
      container: true,
      label: '$title. $location. ${context.l10n.requestsOpenDetails}',
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXxl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.lg,
              BatshSpacing.lg,
              BatshSpacing.lg,
              BatshSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    _RequestMark(locked: locked),
                  ],
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  context.l10n.requestsQuoteType,
                  textAlign: TextAlign.end,
                  style: BatshTypography.bodyLg.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: BatshSpacing.sm),
                _MetaRow(icon: Icons.location_on_outlined, text: location),
                const SizedBox(height: BatshSpacing.xs),
                _MetaRow(
                  icon: Icons.schedule_outlined,
                  text: context.l10n.requestsPublishedOn(date),
                ),
                const SizedBox(height: BatshSpacing.md),
                _ContactPreview(locked: locked),
                const SizedBox(height: BatshSpacing.md),
                if (locked)
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.lg,
                        vertical: BatshSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.secondary,
                        borderRadius: BatshRadius.brFull,
                        boxShadow: BatshShadows.subtle,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: context.colorScheme.onSecondary,
                            size: BatshIconSize.md,
                          ),
                          const SizedBox(width: BatshSpacing.sm),
                          Flexible(
                            child: Text(
                              context.l10n.requestsLockedWithPro,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BatshTypography.labelLg.copyWith(
                                color: context.colorScheme.onSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      borderRadius: BatshRadius.brLg,
                    ),
                    child: Text(
                      context.l10n.requestsProContactAvailable,
                      style: BatshTypography.labelLg.copyWith(
                        color: context.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: BatshSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.requestsOpenDetails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Icon(
                      Icons.arrow_back_rounded,
                      size: BatshIconSize.sm,
                      color: context.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestMark extends StatelessWidget {
  const _RequestMark({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        locked ? Icons.lock_outline_rounded : Icons.check_rounded,
        color: context.colorScheme.onSecondaryContainer,
        size: BatshIconSize.md,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: BatshSpacing.xs),
        Icon(
          icon,
          size: BatshIconSize.md,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _ContactPreview extends StatelessWidget {
  const _ContactPreview({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurfaceVariant.withValues(alpha: 0.52);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.md,
        vertical: BatshSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brLg,
      ),
      child: Column(
        children: [
          _ObscuredContactRow(
            icon: Icons.phone_outlined,
            text: locked
                ? context.l10n.requestsProtectedContact
                : context.l10n.requestsProContactAvailable,
            color: color,
          ),
          const Divider(height: BatshSpacing.md),
          _ObscuredContactRow(
            icon: Icons.pin_drop_outlined,
            text: locked
                ? context.l10n.requestsProtectedContact
                : context.l10n.requestsLocationVisible,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _ObscuredContactRow extends StatelessWidget {
  const _ObscuredContactRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: BatshIconSize.md, color: color),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.bodyMd.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class RequestsProConversionCard extends StatelessWidget {
  const RequestsProConversionCard({
    super.key,
    required this.annual,
    required this.onAnnualChanged,
    required this.onSubscribe,
    required this.isLoading,
    required this.trialAvailable,
  });

  final bool annual;
  final ValueChanged<bool> onAnnualChanged;
  final VoidCallback? onSubscribe;
  final bool isLoading;
  final bool trialAvailable;

  @override
  Widget build(BuildContext context) {
    final price = BatshPricing.proPrice(annual: annual);
    return Semantics(
      container: true,
      label: context.l10n.requestsProHeadline,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.xl,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brXxl,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
          boxShadow: BatshShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.requestsProHeadline,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              context.l10n.requestsProEmphasis,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineMd.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              context.l10n.requestsProDescription,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyLg.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            _ProBenefits(),
            const SizedBox(height: BatshSpacing.lg),
            _PlanToggle(annual: annual, onChanged: onAnnualChanged),
            const SizedBox(height: BatshSpacing.md),
            Text(
              '${_digits(context, price)} ${context.l10n.egpUnit} ${annual ? context.l10n.perYear : context.l10n.perMonth}',
              textAlign: TextAlign.center,
              style: BatshTypography.displayMd.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              annual
                  ? context.l10n.requestsAnnualSaving(
                      _digits(
                        context,
                        BatshPricing.proMonthlyEgp * 12 -
                            BatshPricing.proAnnualEgp,
                      ),
                    )
                  : trialAvailable
                  ? context.l10n.requestsTrialBilling
                  : context.l10n.requestsPaidBilling,
              textAlign: TextAlign.center,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshButton(
              label: trialAvailable
                  ? context.l10n.requestsCtaTrial
                  : context.l10n.requestsCtaPaid,
              icon: Icons.lock_open_rounded,
              isLoading: isLoading,
              onPressed: onSubscribe,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              context.l10n.requestsPaymentNote,
              textAlign: TextAlign.center,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProBenefits extends StatelessWidget {
  const _ProBenefits();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProBenefit(
          icon: Icons.phone_in_talk_outlined,
          text: context.l10n.requestsBenefitContact,
        ),
        _ProBenefit(
          icon: Icons.all_inclusive_rounded,
          text: context.l10n.requestsBenefitUnlimited,
        ),
        _ProBenefit(
          icon: Icons.search_rounded,
          text: context.l10n.requestsBenefitRanking,
        ),
      ],
    );
  }
}

class _ProBenefit extends StatelessWidget {
  const _ProBenefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: BatshIconSize.md,
              color: context.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: BatshSpacing.md),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.end,
              style: BatshTypography.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanToggle extends StatelessWidget {
  const _PlanToggle({required this.annual, required this.onChanged});

  final bool annual;
  final ValueChanged<bool> onChanged;

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
          _PlanSegment(
            label: context.l10n.planMonthly,
            selected: !annual,
            onTap: () => onChanged(false),
          ),
          _PlanSegment(
            label: context.l10n.planAnnual,
            selected: annual,
            badge: context.l10n.annualSaveBadge,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _PlanSegment extends StatelessWidget {
  const _PlanSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? context.colorScheme.surfaceContainerLowest
                  : Colors.transparent,
              borderRadius: BatshRadius.brFull,
              border: selected
                  ? Border.all(
                      color: context.colorScheme.primary.withValues(
                        alpha: 0.55,
                      ),
                    )
                  : null,
              boxShadow: selected ? BatshShadows.subtle : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: BatshTypography.labelLg.copyWith(
                      color: selected
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: BatshSpacing.xs),
                    Text(
                      badge!,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _digits(BuildContext context, Object value) {
  final raw = value.toString();
  if (Localizations.localeOf(context).languageCode != 'ar') return raw;
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  return raw.replaceAllMapped(
    RegExp(r'[0-9]'),
    (match) => arabicDigits[int.parse(match[0]!)],
  );
}
