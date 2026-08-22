import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../../discovery/presentation/widgets/mockup_assets.dart';

const double homeGutter = BatshSpacing.marginMobile;

/// Shared account/menu identity strip kept for the existing golden coverage.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.onMenuTap,
  });

  final int unreadCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo_wordmark.png',
              height: 44,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _HomeNotificationButton(
                unreadCount: unreadCount,
                onTap: onNotificationTap,
              ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _HomeIconButton(
                icon: Icons.menu_rounded,
                semanticLabel: context.l10n.accountSettingsTitle,
                onTap: onMenuTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeIconButton extends StatelessWidget {
  const _HomeIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.child,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: BatshSpacing.minHitArea,
            height: BatshSpacing.minHitArea,
            child:
                child ??
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: 26,
                    color: context.colorScheme.primary,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _HomeNotificationButton extends StatelessWidget {
  const _HomeNotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeIconButton(
      icon: Icons.notifications_none_rounded,
      semanticLabel: context.l10n.notificationsTitle,
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.notifications_none_rounded,
              size: 26,
              color: context.colorScheme.primary,
            ),
          ),
          if (unreadCount > 0)
            PositionedDirectional(
              end: 10,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: context.colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The homeowner's first decision surface: a clear promise, a warm interior,
/// and one practical browse action.
///
/// The image keeps the existing campaign asset and routes. Its boundary is a
/// quiet architectural roofline rather than a hard diagonal, which protects
/// the Arabic message and lets the photograph support the action instead of
/// competing with it.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.locationLabel,
    required this.unreadCount,
    this.searchController,
    this.onSearchSubmitted,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onMenuTap,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.showDiscoveryControls = true,
  });

  final String? locationLabel;
  final int unreadCount;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onMenuTap;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final bool showDiscoveryControls;

  static const double _height = 326;
  static const double _bottomRadius = 34;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final leadSize = compact ? 30.0 : 32.0;
    final restSize = compact ? 25.0 : 27.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth * 0.5;
        final heroHeight = showDiscoveryControls
            ? (compact ? 314.0 : _height)
            : (compact ? 246.0 : 258.0);
        return SizedBox(
          height: heroHeight,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(_bottomRadius),
              bottomRight: Radius.circular(_bottomRadius),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: BatshColors.primary),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ShattabPattern(
                        kind: ShattabPatternKind.terrazzo,
                        color: Colors.white,
                        opacity: 0.14,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ClipPath(
                    clipper: const _HomeHeroPhotoClipper(),
                    child: MockupImage(
                      url: mockupHeroImage,
                      memCacheWidth: 1440,
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _HomeHeroRooflinePainter()),
                  ),
                ),
                Positioned(
                  left: homeGutter + 2,
                  top: compact ? 76 : 80,
                  width: panelWidth - (homeGutter * 2) - 4,
                  child: Semantics(
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.homeHeroTitleLead,
                          textAlign: TextAlign.center,
                          style: BatshTypography.displayMd.copyWith(
                            color: Colors.white,
                            fontSize: leadSize,
                            height: 1.18,
                          ),
                        ),
                        Text(
                          context.l10n.homeHeroTitleRest,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: BatshTypography.headlineLg.copyWith(
                            color: Colors.white,
                            fontSize: restSize,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.xs),
                        Text(
                          context.l10n.homeHeroSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Positioned(
                        left: homeGutter,
                        top: BatshSpacing.sm,
                        child: _LocationPill(
                          label: locationLabel?.trim().isNotEmpty == true
                              ? locationLabel!.trim()
                              : context.l10n.cityNewCairo,
                          onTap: onLocationTap,
                        ),
                      ),
                      Positioned(
                        right: homeGutter,
                        top: BatshSpacing.sm,
                        child: _HeroCircleButton(
                          semanticLabel: context.l10n.notificationsTitle,
                          onTap: onNotificationTap,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                size: BatshIconSize.action,
                                color: BatshColors.primary,
                              ),
                              if (unreadCount > 0)
                                PositionedDirectional(
                                  end: -6,
                                  top: -7,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                    ),
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: BatshColors.primary,
                                      shape: BoxShape.circle,
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
                      Positioned(
                        right: homeGutter + 52,
                        top: BatshSpacing.sm,
                        child: _HeroCircleButton(
                          semanticLabel: context.l10n.accountSettingsTitle,
                          onTap: onMenuTap,
                          child: const ShattabMotifIcon(
                            motif: ShattabMotif.tile,
                            color: BatshColors.primary,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDiscoveryControls)
                  Positioned(
                    left: homeGutter,
                    right: homeGutter,
                    bottom: BatshSpacing.lg,
                    child: Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: HomeSearchField(
                            controller: searchController!,
                            onSubmitted: onSearchSubmitted!,
                          ),
                        ),
                        const SizedBox(width: BatshSpacing.sm),
                        SizedBox(
                          width: compact ? 108 : 104,
                          child: _HomeHeroFilterButton(
                            activeCount: activeFilterCount,
                            onTap: onFilterTap!,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: BatshSpacing.minHitArea,
            height: BatshSpacing.minHitArea,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _HomeHeroPhotoClipper extends CustomClipper<Path> {
  const _HomeHeroPhotoClipper();

  @override
  Path getClip(Size size) => _homeHeroPhotoPath(size);

  @override
  bool shouldReclip(covariant _HomeHeroPhotoClipper oldClipper) => false;
}

class _HomeHeroRooflinePainter extends CustomPainter {
  const _HomeHeroRooflinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_homeHeroPhotoPath(size), paint);
  }

  @override
  bool shouldRepaint(covariant _HomeHeroRooflinePainter oldDelegate) => false;
}

Path _homeHeroPhotoPath(Size size) {
  return Path()
    ..moveTo(size.width * 0.53, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width * 0.34, size.height)
    ..cubicTo(
      size.width * 0.39,
      size.height * 0.78,
      size.width * 0.49,
      size.height * 0.30,
      size.width * 0.53,
      0,
    )
    ..close();
}

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brFull,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.68),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        textAlign: TextAlign.right,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: scheme.primary,
        style: BatshTypography.bodyMd.copyWith(color: scheme.onSurface),
        decoration: InputDecoration(
          hintText: context.l10n.homeSearchHint,
          hintStyle: BatshTypography.bodyLg.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 15,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.md,
          ),
          suffixIcon: SizedBox(
            width: 48,
            child: Center(
              child: Icon(
                Icons.search_rounded,
                size: BatshIconSize.md,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 48,
            maxWidth: 48,
          ),
        ),
      ),
    );
  }
}

class _HomeHeroFilterButton extends StatelessWidget {
  const _HomeHeroFilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = activeCount > 0;
    final foreground = isActive ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: isActive
          ? context.l10n.filterWithCount(activeCount)
          : context.l10n.filter,
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brFull,
              border: Border.all(
                color: isActive
                    ? scheme.primary.withValues(alpha: 0.45)
                    : scheme.outlineVariant.withValues(alpha: 0.68),
              ),
              boxShadow: BatshShadows.soft,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isActive
                        ? context.l10n.filterWithCount(activeCount)
                        : context.l10n.filter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelMd.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Icon(
                  Icons.tune_rounded,
                  size: BatshIconSize.md,
                  color: foreground,
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
  const _LocationPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      button: true,
      label: '${context.l10n.filterCity}: $label',
      hint: context.l10n.changeLocation,
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: BatshSpacing.minHitArea,
              maxWidth: 260,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.md,
              vertical: BatshSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brFull,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.75),
              ),
              boxShadow: BatshShadows.soft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: BatshIconSize.inline,
                  color: scheme.primary,
                ),
                const SizedBox(width: BatshSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelLg.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
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
