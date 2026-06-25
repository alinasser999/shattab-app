import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';

class BatshLoading extends StatelessWidget {
  const BatshLoading({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(
          color: BatshColors.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
