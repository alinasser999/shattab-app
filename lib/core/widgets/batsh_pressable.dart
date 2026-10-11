import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_motion.dart';

/// How firmly a tap answers back.
///
/// [selection] is the default: the light tick that says "registered", for
/// navigation, chips and neutral actions. [light] is a real bump, reserved for
/// taps the person *meant* — liking, saving, committing. Spending the stronger
/// one on everything makes it mean nothing.
enum HapticStrength { selection, light }

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

  bool _focused = false;

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
      child: ConstrainedBox(
        constraints: _interactive
            ? const BoxConstraints(minWidth: 48, minHeight: 48)
            : const BoxConstraints(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _focused
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );

    if (_interactive) {
      result = GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: (_) => _release(BatshMotion.springTap),
        onTapCancel: () => _release(BatshMotion.easeOut),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: result,
      );
    }

    if (!_interactive) return result;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: widget.onTap != null,
        enabled: true,
        label: widget.semanticLabel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        // Independent buttons inside a card remain their own semantic nodes.
        explicitChildNodes: widget.semanticLabel != null,
        child: result,
      ),
    );
  }
}
