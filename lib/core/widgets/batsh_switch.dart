import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native switch provides keyboard, focus and a single toggled semantic node.
class BatshSwitch extends StatelessWidget {
  const BatshSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Switch(
    value: value,
    onChanged: (next) {
      HapticFeedback.selectionClick();
      onChanged(next);
    },
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
