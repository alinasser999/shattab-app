import 'package:flutter/material.dart';

class BatshPatternBackground extends StatelessWidget {
  final Widget child;

  const BatshPatternBackground({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}
