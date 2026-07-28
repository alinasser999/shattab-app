import 'package:flutter/material.dart';

class BatshFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const BatshFab({Key? key, required this.onPressed, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(onPressed: onPressed, child: child);
  }
}
