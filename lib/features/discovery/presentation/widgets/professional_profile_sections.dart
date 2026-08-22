import 'package:flutter/material.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../domain/contractor_listing.dart';
import '../../domain/trust_signals.dart';
import 'mockup_assets.dart';

/// Screen edges for the professional profile.
const double profileGutter = BatshSpacing.marginMobile;

// ─── Trust tiles ─────────────────────────────────────────────────────────────

/// The claims a homeowner scans before deciding whether to keep reading.
///
/// Built from what the record actually says. The reference offers four tiles,
/// the fourth being a response time — this app has no such measurement, and the
/// column that looks like one (`response_rate`) is a constant defaulting to
/// 100, which is exactly why `ContractorListing` deliberately does not read it.
/// A tile reading "replies within an hour" over a defaulted column is a
/// fabricated trust claim on the screen where trust is the whole decision, so
/// the row renders however many tiles are true.
class ProfileStatTiles extends StatelessWidget {
  const ProfileStatTiles({super.key, required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final tiles = <({IconData icon, String value, String label})>[
      if (listing.verified)
        (
          icon: Icons.verified_user_outlined,
          value: context.l10n.verified,
          label: context.l10n.profileVerifiedStat,
        ),
      if (listing.projectsCompleted > 0)
        (
          icon: Icons.groups_2_outlined,
          value: '${listing.projectsCompleted}+',
          label: context.l10n.completedProjectsShort,
        ),
      if (listing.yearsExperience != null && listing.yearsExperience! > 0)
        (
          icon: Icons.work_outline_rounded,
          value: '${listing.yearsExperience}',
          label: context.l10n.yearsExperience,
        ),
      if (listing.hasReviews)
        (
          icon: Icons.star_border_rounded,
          value: '${listing.reviewCount}',
          label: context.l10n.reviewsCount,
        ),
    ];

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: profileGutter),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: BatshSpacing.xs),
              Expanded(
                child: _StatTile(
                  icon: tiles[i].icon,
                  value: tiles[i].value,
                  label: tiles[i].label,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact evidence panel built only from signals the listing actually
/// contains. It gives a homeowner a reason to trust the profile without
/// inventing response-time or completion-rate claims.
class ProfileTrustEvidence extends StatelessWidget {
  const ProfileTrustEvidence({super.key, required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final trust = TrustProfile.of(context, listing);
    final evidence = <({IconData icon, String label})>[
      if (trust.verification != VerificationLevel.none)
        (
          icon: Icons.verified_user_outlined,
          label: context.l10n.verifiedIdentity,
        ),
      for (final metric in trust.metrics)
        (icon: _trustIcon(metric.kind), label: metric.semanticLabel),
      if (listing.hasReviews)
        (
          icon: Icons.star_outline_rounded,
          label: '${listing.reviewCount} ${context.l10n.reviewsCount}',
        ),
      if (listing.hasReviews)
        (
          icon: Icons.verified_outlined,
          label: context.l10n.verifiedReviewFromCompletedJob,
        ),
      if (trust.highlight != null)
        (
          icon: Icons.workspace_premium_outlined,
          label: _highlightLabel(context, trust.highlight!),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: profileGutter),
      child: Container(
        padding: const EdgeInsets.all(BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          boxShadow: BatshShadows.soft,
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -24,
              end: -24,
              width: 150,
              height: 120,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0.18,
                    child: ShattabPattern(
                      kind: ShattabPatternKind.arches,
                      color: context.colorScheme.primary,
                      opacity: 0.55,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.trustEvidenceTitle,
                  style: BatshTypography.titleMd.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  context.l10n.trustEvidenceBody,
                  style: BatshTypography.bodySm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: BatshSpacing.md),
                if (evidence.isEmpty)
                  _TrustEvidenceRow(
                    icon: Icons.person_outline_rounded,
                    label: context.l10n.trustNewProfessional,
                  )
                else
                  for (final item in evidence)
                    _TrustEvidenceRow(icon: item.icon, label: item.label),
                const SizedBox(height: BatshSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: BatshIconSize.inline,
                      color: context.colorScheme.secondary,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Expanded(
                      child: Text(
                        context.l10n.trustSafetyBody,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _trustIcon(TrustSignalKind kind) => switch (kind) {
    TrustSignalKind.projectsCompleted => Icons.home_work_outlined,
    TrustSignalKind.yearsExperience => Icons.work_history_outlined,
  };

  String _highlightLabel(BuildContext context, TrustHighlight highlight) =>
      switch (highlight) {
        TrustHighlight.topRated => context.l10n.highlightTopRated,
        TrustHighlight.established => context.l10n.highlightEstablished,
      };
}

class _TrustEvidenceRow extends StatelessWidget {
  const _TrustEvidenceRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: BatshIconSize.md,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.xxs,
          vertical: BatshSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brLg,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: BatshIconSize.action,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: BatshSpacing.xs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section navigator ───────────────────────────────────────────────────────

/// Jumps to a section rather than swapping one out.
///
/// Drawn as tabs because the reference draws them as tabs, but this page is one
/// scroll: a real `TabBarView` would hide the work behind the reviews and the
/// reviews behind the work, and the whole argument for hiring somebody is being
/// able to see all of it at once.
class ProfileSectionTabs extends StatelessWidget {
  const ProfileSectionTabs({
    super.key,
    required this.labels,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      // Spread across the width when they fit, scroll when they do not. A
      // fixed scroll view left the tabs bunched at the reading edge with dead
      // space opposite; a fixed Row would clip them once a label grows.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabs = [
            for (var i = 0; i < labels.length; i++)
              _Tab(
                label: labels[i],
                selected: i == currentIndex,
                onTap: () => onSelect(i),
              ),
          ];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: profileGutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth - profileGutter * 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tabs,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colorScheme.primary
        : context.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: BatshSpacing.minHitArea),
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? color : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: BatshTypography.labelLg.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── About ───────────────────────────────────────────────────────────────────

/// What the company says about itself, clamped until asked.
///
/// Three lines is enough to judge whether the rest is worth reading, and the
/// toggle appears only when there is actually more — a "show more" that expands
/// nothing is a broken control.
class ProfileAboutCard extends StatefulWidget {
  const ProfileAboutCard({super.key, required this.text});

  final String text;

  @override
  State<ProfileAboutCard> createState() => _ProfileAboutCardState();
}

class _ProfileAboutCardState extends State<ProfileAboutCard> {
  bool _expanded = false;

  static const int _collapsedLines = 3;

  @override
  Widget build(BuildContext context) {
    final style = BatshTypography.bodyLg.copyWith(
      height: 1.7,
      color: context.colorScheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure before offering the toggle, so it is shown only when there is
        // something behind it.
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            if (overflows)
              Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xs),
                child: _ExpandToggle(
                  expanded: _expanded,
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = expanded
        ? context.l10n.profileShowLess
        : context.l10n.profileShowMore;
    return Semantics(
      button: true,
      expanded: expanded,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brSm,
        child: Container(
          constraints: const BoxConstraints(minHeight: BatshSpacing.minHitArea),
          alignment: AlignmentDirectional.centerStart,
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: BatshTypography.labelLg.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: BatshSpacing.xxs),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: BatshIconSize.md,
                  color: context.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Services ────────────────────────────────────────────────────────────────

/// The trades this professional actually registered, as glyph tiles.
///
/// Same treatment and same icon vocabulary as the home page's category row, via
/// the shared [specialtyIcon] — a homeowner who tapped "plumbing" on the home
/// page should meet the same mark here.
class ProfileServicesRow extends StatelessWidget {
  const ProfileServicesRow({super.key, required this.specialties});

  final List<String> specialties;

  static const double _tileWidth = 68;

  @override
  Widget build(BuildContext context) {
    if (specialties.isEmpty) return const SizedBox.shrink();
    final hasLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;

    return SizedBox(
      height: hasLargeText ? 104 : 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: profileGutter),
        physics: const BouncingScrollPhysics(),
        itemCount: specialties.length,
        separatorBuilder: (_, _) => const SizedBox(width: BatshSpacing.xs),
        itemBuilder: (_, index) {
          final key = specialties[index];
          final label = localizedSpecialtyLabel(context, key);
          return SizedBox(
            width: _tileWidth,
            child: Semantics(
              label: label,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.xxs,
                  vertical: BatshSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLow,
                  borderRadius: BatshRadius.brLg,
                ),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        specialtyIcon(key),
                        size: BatshIconSize.action,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(height: BatshSpacing.xs),
                      Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Completed projects ──────────────────────────────────────────────────────

/// Finished work, filterable by property type.
///
/// The chips come from the `apartment_type` the contractor set on their own
/// projects rather than from a fixed list, so somebody who has only ever done
/// flats is never shown an empty "offices" filter. The completion badge is
/// likewise driven by `year_completed` being present rather than painted on
/// everything.
class ProfileProjectsGrid extends StatefulWidget {
  const ProfileProjectsGrid({
    super.key,
    required this.projects,
    required this.onOpen,
  });

  final List<PortfolioProject> projects;
  final ValueChanged<PortfolioProject> onOpen;

  @override
  State<ProfileProjectsGrid> createState() => _ProfileProjectsGridState();
}

class _ProfileProjectsGridState extends State<ProfileProjectsGrid> {
  String? _type;

  List<String> get _types {
    final seen = <String>{};
    for (final project in widget.projects) {
      final type = project.apartmentType?.trim();
      if (type != null && type.isNotEmpty) seen.add(type);
    }
    return seen.toList();
  }

  @override
  Widget build(BuildContext context) {
    final types = _types;
    final visible = _type == null
        ? widget.projects
        : widget.projects.where((p) => p.apartmentType == _type).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Only worth a filter row when there is more than one thing to filter.
        if (types.length > 1) ...[
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: profileGutter),
              itemCount: types.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: BatshSpacing.xs),
              itemBuilder: (_, index) {
                final value = index == 0 ? null : types[index - 1];
                return _FilterChip(
                  label: value ?? context.l10n.profileFilterAll,
                  selected: _type == value,
                  onTap: () => setState(() => _type = value),
                );
              },
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: profileGutter),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: BatshSpacing.sm,
              mainAxisSpacing: BatshSpacing.sm,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (_, index) => _ProjectTile(
              project: visible[index],
              onTap: () => widget.onOpen(visible[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? context.colorScheme.primary
            : context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brFull,
              border: Border.all(
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant,
              ),
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                style: BatshTypography.labelMd.copyWith(
                  color: selected
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.onTap});

  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final where = project.location?.trim();
    return ClipRRect(
      borderRadius: BatshRadius.brLg,
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: project.title,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MockupImage(url: project.coverPhotoUrl, memCacheWidth: 520),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0xD9000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
            // Earned by the record rather than painted on everything: a project
            // reads as finished only when it carries a completion year.
            if (project.yearCompleted != null)
              PositionedDirectional(
                top: BatshSpacing.xs,
                start: BatshSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BatshSpacing.xs,
                    vertical: BatshSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: BatshColors.secondary,
                    borderRadius: BatshRadius.brFull,
                  ),
                  child: Text(
                    context.l10n.completedProjectsShort,
                    style: BatshTypography.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              start: BatshSpacing.xs,
              end: BatshSpacing.xs,
              bottom: BatshSpacing.xs,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (where != null && where.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: BatshSpacing.xxxs),
                          Flexible(
                            child: Text(
                              where,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BatshTypography.labelSm.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Closing call to action ──────────────────────────────────────────────────

/// The page's last word.
///
/// A homeowner who has read the whole profile has already scrolled past the
/// buttons at the top; asking again at the bottom is the difference between a
/// page that stops and a page that closes.
class ProfileClosingCta extends StatelessWidget {
  const ProfileClosingCta({super.key, required this.onRequestQuote});

  final VoidCallback onRequestQuote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: profileGutter),
      child: ClipRRect(
        borderRadius: BatshRadius.brCard,
        child: Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: BatshShadows.soft,
          ),
          child: Stack(
            children: [
              const PositionedDirectional(
                start: -30,
                bottom: -30,
                width: 150,
                height: 150,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: ShattabPattern(
                      kind: ShattabPatternKind.arches,
                      color: BatshColors.patternLine,
                      opacity: 0.4,
                    ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.profileClosingTitle,
                                style: BatshTypography.headlineSm.copyWith(
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: BatshSpacing.xxs),
                              Text(
                                context.l10n.profileClosingBody,
                                style: BatshTypography.bodyMd.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: BatshSpacing.sm),
                        ExcludeSemantics(
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              // primaryContainer, not primaryFixed: the
                              // fixed roles are absent from BatshColors.scheme,
                              // so asking for one gets Material's derived
                              // fallback — which renders as a dark plate under
                              // a dark glyph.
                              color: context.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.phone_in_talk_outlined,
                              color: context.colorScheme.primary,
                              size: BatshIconSize.action,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BatshSpacing.md),
                    _ClosingButton(onTap: onRequestQuote),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosingButton extends StatelessWidget {
  const _ClosingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.profileClosingAction,
      child: Material(
        color: context.colorScheme.primary,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
            child: ExcludeSemantics(
              child: Text(
                context.l10n.profileClosingAction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.titleMd.copyWith(
                  color: context.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
