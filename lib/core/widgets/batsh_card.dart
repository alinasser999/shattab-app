import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/batsh_motion.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshCard extends StatefulWidget {
  const BatshCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BatshSpacing.gutter),
    this.onTap,
    this.elevated = false,
    this.selected = false,
    this.highlightColor,
    this.primary = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool elevated;
  final bool selected;
  final Color? highlightColor;
  final bool primary;

  @override
  State<BatshCard> createState() => _BatshCardState();
}

class _BatshCardState extends State<BatshCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: BatshMotion.fast,
    value: 0.0,
  );

  bool _isHovered = false;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  void _onTapDown(_) {
    if (widget.onTap == null || _reduced) return;
    _ctrl.animateTo(1, duration: BatshMotion.fast, curve: BatshMotion.easeOut);
  }

  void _onTapUp(_) {
    if (_reduced) return;
    _ctrl.animateTo(
      0,
      duration: BatshMotion.normal,
      curve: BatshMotion.springTap,
    );
  }

  void _onTapCancel() {
    if (_reduced) return;
    _ctrl.animateTo(0, duration: BatshMotion.fast, curve: BatshMotion.easeOut);
  }

  void _onHoverEnter(PointerEnterEvent _) {
    if (!_reduced) setState(() => _isHovered = true);
  }

  void _onHoverExit(PointerExitEvent _) {
    setState(() => _isHovered = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (widget.primary) {
      bgColor = context.colorScheme.primaryContainer;
    } else if (widget.selected) {
      bgColor = context.colorScheme.primaryFixed.withValues(alpha: 0.35);
    } else {
      bgColor = context.colorScheme.surface;
    }

    final border = widget.selected
        ? Border.all(color: context.colorScheme.primary, width: 2)
        : null;

    final defaultShadow = widget.elevated
        ? BatshShadows.elevated
        : BatshShadows.soft;

    final content = AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value.clamp(0.0, 1.0);
        final scale = _reduced ? 1.0 : (1.0 - 0.03 * t);
        final shadow = _reduced
            ? defaultShadow
            : _isHovered
            ? BatshShadows.elevated
            : _lerpShadows(defaultShadow, BatshShadows.elevated, t);
        final hoverY = _isHovered && !_reduced ? -1.0 : 0.0;

        return Transform.translate(
          offset: Offset(0, hoverY),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BatshRadius.brCard,
                border: border,
                boxShadow: shadow,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );

    Widget result = content;

    if (widget.onTap != null) {
      result = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: result,
      );
    }

    result = MouseRegion(
      onEnter: _onHoverEnter,
      onExit: _onHoverExit,
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: result,
    );

    return Semantics(button: widget.onTap != null, child: result);
  }

  List<BoxShadow> _lerpShadows(List<BoxShadow> a, List<BoxShadow> b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return [
      for (int i = 0; i < a.length && i < b.length; i++)
        BoxShadow.lerp(a[i], b[i], t)!,
    ];
  }
}
