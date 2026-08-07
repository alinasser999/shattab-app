import 'package:flutter/material.dart';

class BatshPatternBackground extends StatelessWidget {
  final Widget child;

  const BatshPatternBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}
