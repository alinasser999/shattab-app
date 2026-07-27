import 'package:flutter/material.dart';

import '../theme/batsh_motion.dart';

/// Bare press-scale interaction, extracted from [BatshCard] so image tiles and
/// custom-decorated cards get the same tactile feedback without inheriting a
/// card's background/padding. Scales down on press, springs back on release.
///
/// Honours reduced-motion (no scale, just passes taps through) and exposes a
/// button semantics node so screen readers announce it correctly.
class BatshPressable extends StatefulWidget {
  const BatshPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale at full press. 0.97 matches [BatshCard]; go slightly lower (0.95)
  /// for large hero tiles where the travel should read stronger.
  final double pressedScale;

  final String? semanticLabel;

  @override
  State<BatshPressable> createState() => _BatshPressableState();
}

class _BatshPressableState extends State<BatshPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: BatshMotion.fast,
    value: 0.0,
  );

  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _onTapDown(_) {
    if (!_interactive || _reduced) return;
    _ctrl.animateTo(1, duration: BatshMotion.fast, curve: BatshMotion.easeOut);
  }

  void _release(Curve curve) {
    if (_reduced) return;
    _ctrl.animateTo(0, duration: BatshMotion.normal, curve: curve);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value.clamp(0.0, 1.0);
        final scale = _reduced ? 1.0 : 1.0 - (1.0 - widget.pressedScale) * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );

    if (_interactive) {
      result = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: (_) => _release(BatshMotion.springTap),
        onTapCancel: () => _release(BatshMotion.easeOut),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: result,
      );
    }

    return Semantics(
      button: _interactive,
      label: widget.semanticLabel,
      child: result,
    );
  }
}
