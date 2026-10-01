import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshBottomNavItem {
  const BatshBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating premium bottom nav — detached stadium bar with soft elevation,
/// an animated active pill, and spring icon scaling. Token-driven, RTL-safe
/// (Row follows the ambient Directionality; no hardcoded left/right).
class BatshBottomNav extends StatelessWidget {
  const BatshBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.anchored = false,
    this.fontFamily,
  });

  final List<BatshBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;

  /// Edge-to-edge reference bar for the contractor work page. Floating remains
  /// the default used by every other shell.
  final bool anchored;
  final String? fontFamily;

  /// Extra scroll room for floating navigation bars. The Scaffold reserves the
  /// bar's layout height, but the stadium itself is transparent around its
  /// edges and can still visually sit over the last card in a scroll view.
  static double contentBottomInset(BuildContext context) =>
      112 + MediaQuery.of(context).padding.bottom;

  @override
  Widget build(BuildContext context) {
    if (anchored) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? context.colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: context.colorScheme.outlineVariant.withValues(alpha: .65),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _AnchoredNavItem(
                      item: items[i],
                      selected: currentIndex == i,
                      fontFamily: fontFamily,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final isCompact = MediaQuery.sizeOf(context).width <= 340;
    final horizontalInset = isCompact ? 0.0 : BatshSpacing.ml;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: BatshSpacing.xxs),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          BatshSpacing.xs,
          horizontalInset,
          0,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                backgroundColor ?? context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brFull,
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isCompact ? 0 : 1,
            ),
            boxShadow: BatshShadows.floating,
          ),
          child: ClipRRect(
            borderRadius: BatshRadius.brFull,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItem(
                        item: items[i],
                        isSelected: currentIndex == i,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnchoredNavItem extends StatelessWidget {
  const _AnchoredNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    this.fontFamily,
  });

  final BatshBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: item.label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.xxs,
            vertical: BatshSpacing.xxs,
          ),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : BatshMotion.fast,
            curve: BatshMotion.easeOut,
            decoration: BoxDecoration(
              color: selected
                  ? context.colorScheme.primaryContainer.withValues(alpha: .78)
                  : Colors.transparent,
              borderRadius: BatshRadius.brMd,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: BatshIconSize.md,
                  color: selected
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurface,
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: BatshTypography.labelSm.copyWith(
                      fontFamily: fontFamily,
                      color: selected
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final BatshBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _pillAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: BatshMotion.normal,
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: BatshMotion.springTap,
    );
    _pillAnim = CurvedAnimation(
      parent: _controller,
      curve: BatshMotion.easeOut,
    );
    if (widget.isSelected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isSelected != old.isSelected) {
      // Respect the OS reduce-motion setting: snap instead of animate.
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _controller.value = widget.isSelected ? 1.0 : 0.0;
      } else if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width <= 340;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.item.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (_, child) => Transform.scale(
              scale: 0.92 + (_scaleAnim.value * 0.08),
              child: child,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 38,
                  width: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Active pill — grows and fades in behind the icon.
                      AnimatedBuilder(
                        animation: _pillAnim,
                        builder: (_, __) => Container(
                          width: 36 + (_pillAnim.value * 24),
                          height: 38,
                          decoration: BoxDecoration(
                            color: context.colorScheme.primaryContainer
                                .withValues(alpha: _pillAnim.value),
                            borderRadius: BatshRadius.brFull,
                          ),
                        ),
                      ),
                      Icon(
                        widget.isSelected
                            ? widget.item.selectedIcon
                            : widget.item.icon,
                        size: BatshIconSize.md + (_pillAnim.value * 3),
                        color: Color.lerp(
                          context.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
                          context.colorScheme.primary,
                          _pillAnim.value,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxxs),
                // Full-width bound so a long Arabic label ellipsizes instead of
                // overflowing the item on narrow screens.
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 0 : BatshSpacing.xxs,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedDefaultTextStyle(
                      duration: BatshMotion.fast,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      // Solid onSurfaceVariant (not alpha-dimmed) to clear the
                      // 4.5:1 body-text contrast floor on the white bar.
                      style: BatshTypography.labelSm.copyWith(
                        fontSize: 13,
                        color: widget.isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurfaceVariant,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      child: isCompact
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.item.label,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              widget.item.label,
                              textAlign: TextAlign.center,
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
