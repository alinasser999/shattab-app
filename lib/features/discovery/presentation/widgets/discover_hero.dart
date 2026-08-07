import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import 'mockup_assets.dart';

const double _discoverHeroBottomRadius = 32;

/// The discovery cover is deliberately image-led: the first viewport sells a
/// feeling of trust before it asks the homeowner to browse a catalogue.
class DiscoverHero extends StatelessWidget {
  const DiscoverHero({
    super.key,
    required this.searchRow,
    required this.collapsed,
    this.coverUrl,
    this.locationLabel,
    this.onLocationTap,
    this.onNotificationTap,
    this.unreadCount = 0,
  });

  final Widget searchRow;
  final bool collapsed;
  final String? coverUrl;
  final String? locationLabel;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final int unreadCount;

  // Keep the cover image-led without letting it push the useful browse
  // controls below the first viewport on smaller phones.
  static const double _expandedHeight = 324;
  static const double _collapsedHeight = 152;
  static const double _searchOverlap = 0;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: collapsed ? _collapsedHeight : _expandedHeight),
      duration: reduceMotion ? Duration.zero : BatshMotion.normal,
      curve: BatshMotion.heroEase,
      builder: (context, height, _) {
        final reveal =
            ((height - _collapsedHeight) / (_expandedHeight - _collapsedHeight))
                .clamp(0.0, 1.0);
        return SizedBox(
          height: height + _searchOverlap,
          child: Stack(
            children: [
              Positioned.fill(
                bottom: _searchOverlap,
                child: _HeroCover(
                  coverUrl: coverUrl,
                  reveal: reveal,
                  locationLabel: locationLabel,
                  onLocationTap: onLocationTap,
                  onNotificationTap: onNotificationTap,
                  unreadCount: unreadCount,
                ),
              ),
              PositionedDirectional(
                start: BatshSpacing.sectionH,
                end: BatshSpacing.sectionH,
                bottom: BatshSpacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BatshRadius.brFull,
                    boxShadow: BatshShadows.floating,
                  ),
                  child: searchRow,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({
    required this.coverUrl,
    required this.reveal,
    this.locationLabel,
    this.onLocationTap,
    this.onNotificationTap,
    required this.unreadCount,
  });

  final String? coverUrl;
  final double reveal;
  final String? locationLabel;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final url = coverUrl == null || coverUrl!.isEmpty
        ? mockupHeroImage
        : coverUrl;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(_discoverHeroBottomRadius),
        bottomRight: Radius.circular(_discoverHeroBottomRadius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MockupImage(url: url, memCacheWidth: 1440),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x85000000),
                    Color(0x1A000000),
                    Color(0xE6000000),
                  ],
                  stops: [0, 0.44, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                PositionedDirectional(
                  start: BatshSpacing.sectionH,
                  top: BatshSpacing.md,
                  child: _NotificationButton(
                    onTap: onNotificationTap,
                    unreadCount: unreadCount,
                  ),
                ),
                PositionedDirectional(
                  end: BatshSpacing.sectionH,
                  top: BatshSpacing.md,
                  child: _LocationPill(
                    label: locationLabel?.isNotEmpty == true
                        ? locationLabel!
                        : context.l10n.cityNewCairo,
                    onTap: onLocationTap,
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 102,
                  bottom: 88,
                  child: Opacity(
                    opacity: reveal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.discoverHeroTitle,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          style: BatshTypography.displayMd.copyWith(
                            color: Colors.white,
                            fontSize: 31,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.xs),
                        Text(
                          context.l10n.discoverHeroSubtitle,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          style: BatshTypography.bodyLg.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({this.onTap, required this.unreadCount});

  final VoidCallback? onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.notificationsTitle,
      button: onTap != null,
      hint: onTap == null ? null : context.l10n.notificationsSubtitle,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: BatshIconSize.action,
                  ),
                ),
                if (unreadCount > 0)
                  PositionedDirectional(
                    end: -2,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BatshColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textDirection: TextDirection.ltr,
                        style: BatshTypography.labelSm.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${context.l10n.filterCity}: $label',
      hint: onTap == null ? null : context.l10n.changeLocation,
      child: Material(
        color: Colors.transparent,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 190, minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.md,
              vertical: BatshSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.26),
              borderRadius: BatshRadius.brFull,
              border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: BatshIconSize.inline,
                  color: Colors.white,
                ),
                const SizedBox(width: BatshSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelMd.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
