import 'package:flutter/material.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../domain/post.dart';
import 'package:batsh/core/theme/theme_extension.dart';

enum CommunityFeedFilter { all, beforeAfter, tips, experiences, requests }

extension CommunityFeedFilterCopy on CommunityFeedFilter {
  String label(BuildContext context) {
    switch (this) {
      case CommunityFeedFilter.all:
        return context.l10n.communityFilterAll;
      case CommunityFeedFilter.beforeAfter:
        return context.l10n.communityFilterBeforeAfter;
      case CommunityFeedFilter.tips:
        return context.l10n.communityFilterTips;
      case CommunityFeedFilter.experiences:
        return context.l10n.communityFilterExperiences;
      case CommunityFeedFilter.requests:
        return context.l10n.communityFilterRequests;
    }
  }
}

class CommunityPostTypeSheet extends StatelessWidget {
  const CommunityPostTypeSheet({super.key, this.selected});

  final CommunityPostKind? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.sm,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BatshRadius.brFull,
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(
              context.l10n.communityCreatePostTypeTitle,
              textAlign: TextAlign.right,
              style: BatshTypography.titleMd,
            ),
            const SizedBox(height: BatshSpacing.sm),
            for (final kind in CommunityPostKind.values) ...[
              _CommunityPostTypeOption(
                kind: kind,
                selected: selected == kind,
                onTap: () => Navigator.of(context).pop(kind),
              ),
              if (kind != CommunityPostKind.values.last)
                const SizedBox(height: BatshSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunityPostTypeOption extends StatelessWidget {
  const _CommunityPostTypeOption({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final CommunityPostKind kind;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (kind) {
      case CommunityPostKind.standard:
        return Icons.edit_note_outlined;
      case CommunityPostKind.beforeAfter:
        return Icons.compare_arrows_outlined;
      case CommunityPostKind.tips:
        return Icons.lightbulb_outline_rounded;
      case CommunityPostKind.experiences:
        return Icons.auto_awesome_outlined;
      case CommunityPostKind.question:
        return Icons.help_outline_rounded;
    }
  }

  String _title(BuildContext context) {
    switch (kind) {
      case CommunityPostKind.standard:
        return context.l10n.communityPostKindStandard;
      case CommunityPostKind.beforeAfter:
        return context.l10n.communityPostKindBeforeAfter;
      case CommunityPostKind.tips:
        return context.l10n.communityPostKindTips;
      case CommunityPostKind.experiences:
        return context.l10n.communityPostKindExperiences;
      case CommunityPostKind.question:
        return context.l10n.communityPostKindQuestion;
    }
  }

  String _description(BuildContext context) {
    switch (kind) {
      case CommunityPostKind.standard:
        return context.l10n.communityPostKindStandardDescription;
      case CommunityPostKind.beforeAfter:
        return context.l10n.communityPostKindBeforeAfterDescription;
      case CommunityPostKind.tips:
        return context.l10n.communityPostKindTipsDescription;
      case CommunityPostKind.experiences:
        return context.l10n.communityPostKindExperiencesDescription;
      case CommunityPostKind.question:
        return context.l10n.communityPostKindQuestionDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colorScheme.primary
        : context.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: '${_title(context)}، ${_description(context)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(BatshSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? context.colorScheme.primary.withValues(alpha: 0.08)
                : context.colorScheme.surface,
            borderRadius: BatshRadius.brLg,
            border: Border.all(
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colorScheme.primary
                      : context.colorScheme.surfaceContainerHighest,
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(
                  _icon,
                  color: selected
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: BatshSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _title(context),
                      textAlign: TextAlign.right,
                      style: BatshTypography.labelLg.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    Text(
                      _description(context),
                      textAlign: TextAlign.right,
                      style: BatshTypography.bodySm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: color,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The quiet architectural watermark behind the feed. It gives the page its
/// Shattab material language without turning content cards into decorations.
class CommunityPatternBackground extends StatelessWidget {
  const CommunityPatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CommunityPatternPainter(
          line: context.colorScheme.primary.withValues(alpha: 0.055),
          accent: context.colorScheme.secondary.withValues(alpha: 0.045),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CommunityPatternPainter extends CustomPainter {
  const _CommunityPatternPainter({required this.line, required this.accent});

  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint()..color = accent;

    void drawDotMatrix(Offset origin, int columns, int rows) {
      for (var row = 0; row < rows; row++) {
        for (var column = 0; column < columns; column++) {
          canvas.drawCircle(
            origin + Offset(column * 8.0, row * 8.0),
            1.15,
            dot,
          );
        }
      }
    }

    drawDotMatrix(Offset(size.width - 98, 24), 6, 4);
    drawDotMatrix(Offset(18, 286), 5, 4);

    final arch = Path()
      ..moveTo(size.width - 44, 108)
      ..lineTo(size.width - 44, 72)
      ..quadraticBezierTo(size.width - 44, 40, size.width - 12, 40)
      ..lineTo(size.width - 4, 40);
    canvas.drawPath(arch, thin);
    canvas.drawPath(
      arch.shift(const Offset(-9, 8)),
      thin..color = line.withValues(alpha: line.a * 0.72),
    );

    final tile = Path()
      ..moveTo(24, size.height - 116)
      ..lineTo(42, size.height - 116)
      ..lineTo(42, size.height - 98)
      ..lineTo(24, size.height - 98)
      ..close()
      ..moveTo(47, size.height - 116)
      ..lineTo(65, size.height - 116)
      ..lineTo(65, size.height - 98)
      ..lineTo(47, size.height - 98)
      ..close();
    canvas.drawPath(tile, thin);

    final contour = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.57,
        size.width * 0.18,
        size.height * 0.68,
        size.width * 0.34,
        size.height * 0.63,
      );
    canvas.drawPath(contour, thin);
    canvas.drawPath(
      contour.shift(const Offset(0, 10)),
      thin..color = line.withValues(alpha: line.a * 0.7),
    );
  }

  @override
  bool shouldRepaint(_CommunityPatternPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.accent != accent;
}

class CommunityFeedHeader extends StatelessWidget {
  const CommunityFeedHeader({
    super.key,
    required this.onNotifications,
    required this.onFilters,
    this.unreadCount = 0,
  });

  final VoidCallback onNotifications;
  final VoidCallback onFilters;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                label: context.l10n.communityNotificationsLabel,
                onTap: onNotifications,
                unreadCount: unreadCount,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: BatshSpacing.xs),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          const _CommunityMark(),
                          const SizedBox(width: BatshSpacing.xs),
                          Text(
                            context.l10n.communityTitle,
                            textAlign: TextAlign.center,
                            style: BatshTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.communitySubtitle,
                        textAlign: TextAlign.center,
                        style: BatshTypography.bodySm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _HeaderIconButton(
                icon: Icons.tune_rounded,
                label: context.l10n.communityFiltersLabel,
                onTap: onFilters,
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.md),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.unreadCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onTap,
            tooltip: label,
            icon: Icon(icon, size: 25),
            color: context.colorScheme.onSurface,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BatshRadius.brMd,
                side: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 7,
              right: 8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  textDirection: TextDirection.ltr,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommunityMark extends StatelessWidget {
  const _CommunityMark();

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.primary;
    return SizedBox(
      width: 27,
      height: 27,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: _MarkBlock(color: color, width: 12, height: 12),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _MarkBlock(color: color, width: 12, height: 12),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _MarkBlock(color: color, width: 12, height: 12),
          ),
        ],
      ),
    );
  }
}

class _MarkBlock extends StatelessWidget {
  const _MarkBlock({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: BatshRadius.brXs),
      child: SizedBox(width: width, height: height),
    );
  }
}

class FeedFilterChips extends StatelessWidget {
  const FeedFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CommunityFeedFilter selected;
  final ValueChanged<CommunityFeedFilter> onSelected;

  static const filters = CommunityFeedFilter.values;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.l10n.communityFiltersLabel,
      child: SizedBox(
        height: 43,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: BatshSpacing.xs),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = filter == selected;
              return Semantics(
                button: true,
                selected: isSelected,
                label: context.l10n.communityFilterAnnouncement(
                  filter.label(context),
                ),
                onTap: () => onSelected(filter),
                child: GestureDetector(
                  onTap: () => onSelected(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    constraints: const BoxConstraints(minHeight: 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.md,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.colorScheme.surface,
                      borderRadius: BatshRadius.brFull,
                      border: Border.all(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      filter.label(context),
                      style: BatshTypography.labelMd.copyWith(
                        color: isSelected
                            ? context.colorScheme.onPrimary
                            : context.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CommunityFilterSheet extends StatelessWidget {
  const CommunityFilterSheet({super.key, required this.selected});

  final CommunityFeedFilter selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.sm,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BatshRadius.brFull,
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(
              context.l10n.communityFiltersLabel,
              style: BatshTypography.titleMd,
            ),
            const SizedBox(height: BatshSpacing.sm),
            for (final filter in CommunityFeedFilter.values)
              _FilterSheetOption(
                filter: filter,
                selected: filter == selected,
                onTap: () => Navigator.of(context).pop(filter),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetOption extends StatelessWidget {
  const _FilterSheetOption({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final CommunityFeedFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: filter.label(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xs),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.outline,
                size: 24,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Text(
                  filter.label(context),
                  style: BatshTypography.bodyMd.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreatePostComposer extends StatelessWidget {
  const CreatePostComposer({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.onCreate,
    required this.onPhoto,
    required this.onBeforeAfter,
    required this.onQuestion,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onCreate;
  final VoidCallback onPhoto;
  final VoidCallback onBeforeAfter;
  final VoidCallback onQuestion;

  @override
  Widget build(BuildContext context) {
    final surface = context.colorScheme.surfaceContainerLowest;
    return Semantics(
      container: true,
      label: context.l10n.communityCreatePost,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.md,
          BatshSpacing.md,
          BatshSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BatshRadius.brXl,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          boxShadow: BatshShadows.soft,
        ),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AvatarWithInitials(
                    imageUrl: avatarUrl,
                    name: name.isEmpty ? 'م' : name,
                    radius: 22,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        button: true,
                        label: context.l10n.communityCreatePrompt,
                        child: GestureDetector(
                          onTap: onCreate,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 56),
                            padding: const EdgeInsets.symmetric(
                              horizontal: BatshSpacing.md,
                              vertical: BatshSpacing.sm,
                            ),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: context.colorScheme.surface,
                              borderRadius: BatshRadius.brLg,
                              border: Border.all(
                                color: context.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              context.l10n.communityCreatePrompt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: BatshTypography.bodyMd.copyWith(
                                color: context.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.sm),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: onCreate,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: Text(context.l10n.communityCreatePost),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: context.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: BatshSpacing.lg,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BatshRadius.brFull,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.md),
            Divider(
              height: 1,
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _ComposerAction(
                    icon: Icons.image_outlined,
                    label: context.l10n.communityPhotoAction,
                    onTap: onPhoto,
                  ),
                ),
                _ComposerDivider(),
                Expanded(
                  child: _ComposerAction(
                    icon: Icons.compare_outlined,
                    label: context.l10n.communityBeforeAfterAction,
                    onTap: onBeforeAfter,
                  ),
                ),
                _ComposerDivider(),
                Expanded(
                  child: _ComposerAction(
                    icon: Icons.help_outline_rounded,
                    label: context.l10n.communityQuestionAction,
                    onTap: onQuestion,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BatshSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 23, color: context.colorScheme.onSurfaceVariant),
              const SizedBox(width: BatshSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: context.colorScheme.outlineVariant.withValues(alpha: 0.8),
      ),
    );
  }
}

class CommunityEmptyState extends StatelessWidget {
  const CommunityEmptyState({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.lg,
        vertical: BatshSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BatshRadius.brXl,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 42,
            color: context.colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: BatshSpacing.md),
          Text(
            context.l10n.communityNoPostsTitle,
            textAlign: TextAlign.center,
            style: BatshTypography.titleMd,
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.communityNoPostsMessage,
            textAlign: TextAlign.center,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.l10n.communityClearFilter),
          ),
        ],
      ),
    );
  }
}
