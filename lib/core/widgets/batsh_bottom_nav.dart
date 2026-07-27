import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

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
  });

  final List<BatshBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: BatshSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.ml,
          BatshSpacing.xs,
          BatshSpacing.ml,
          0,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BatshColors.surfaceContainerLowest,
            borderRadius: BatshRadius.brFull,
            border: Border.all(
              color: BatshColors.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: BatshShadows.floating,
          ),
          child: ClipRRect(
            borderRadius: BatshRadius.brFull,
            child: SizedBox(
              height: 66,
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
    return GestureDetector(
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
              height: 34,
              width: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Active pill — grows and fades in behind the icon.
                  AnimatedBuilder(
                    animation: _pillAnim,
                    builder: (_, __) => Container(
                      width: 30 + (_pillAnim.value * 26),
                      height: 34,
                      decoration: BoxDecoration(
                        color: BatshColors.primaryContainer
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
                      BatshColors.onSurfaceVariant.withValues(alpha: 0.75),
                      BatshColors.primary,
                      _pillAnim.value,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BatshSpacing.xxs),
            // Full-width bound so a long Arabic label ellipsizes instead of
            // overflowing the item on narrow screens.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xxs),
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
                    color: widget.isSelected
                        ? BatshColors.primary
                        : BatshColors.onSurfaceVariant,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(widget.item.label, textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
