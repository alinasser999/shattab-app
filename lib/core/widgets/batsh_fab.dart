import 'package:flutter/material.dart';

class BatshFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const BatshFab({super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(onPressed: onPressed, child: child);
  }
}
