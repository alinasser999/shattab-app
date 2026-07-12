import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        boxShadow: BatshShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
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
      if (widget.isSelected) {
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
          scale: 0.9 + (_scaleAnim.value * 0.1),
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(),
            SizedBox(
              height: 36,
              width: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pillAnim,
                    builder: (_, child) => Container(
                      width: 24 + (_pillAnim.value * 32),
                      height: 36,
                      decoration: BoxDecoration(
                        color: BatshColors.primaryFixed
                            .withValues(alpha: 0.35 + (_pillAnim.value * 0.25)),
                        borderRadius: BatshRadius.brFull,
                      ),
                    ),
                  ),
                  Icon(
                    widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
                    size: 22 + (_pillAnim.value * 4),
                    color: widget.isSelected
                        ? BatshColors.primary
                        : BatshColors.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BatshSpacing.xxs),
            AnimatedDefaultTextStyle(
              duration: BatshMotion.fast,
              style: BatshTypography.labelSm.copyWith(
                color: widget.isSelected
                    ? BatshColors.primary
                    : BatshColors.onSurfaceVariant.withValues(alpha: 0.55),
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(widget.item.label),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
