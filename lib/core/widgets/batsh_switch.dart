import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_motion.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Premium custom toggle — terracotta track, spring-eased thumb, soft shadow.
/// Replaces stock [Switch] on the account screen so the control reads on-brand.
/// Honors reduced-motion (snaps instead of sliding) and keeps a 48px hit area.
class BatshSwitch extends StatelessWidget {
  const BatshSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _w = 52;
  static const double _h = 30;
  static const double _thumb = 24;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final d = reduced ? Duration.zero : const Duration(milliseconds: 200);
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: SizedBox(
          width: _w,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: d,
              curve: BatshMotion.easeOut,
              width: _w,
              height: _h,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_h),
                color: value
                    ? context.colorScheme.primary
                    : context.colorScheme.surfaceContainerHighest,
              ),
              child: AnimatedAlign(
                duration: d,
                curve: BatshMotion.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: _thumb,
                  height: _thumb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.surfaceContainerLowest,
                    boxShadow: BatshShadows.soft,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
