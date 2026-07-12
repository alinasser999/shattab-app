import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';

/// Read-only star row for a fractional rating in [0, 5].
class BatshStars extends StatelessWidget {
  const BatshStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = BatshColors.tertiary,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating من 5 نجوم',
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i == rating.floor() && rating % 1 >= 0.4;
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: size,
          color: filled || half ? color : BatshColors.surfaceContainerHigh,
        );
      }),
    ));
  }
}

/// Interactive 1–5 star picker.
class BatshStarInput extends StatelessWidget {
  const BatshStarInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final active = star <= value;
        return IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(),
          iconSize: size,
          onPressed: () => onChanged(star),
          icon: Icon(
            active ? Icons.star : Icons.star_border,
            color: active ? BatshColors.tertiary : BatshColors.onSurfaceVariant,
          ),
        );
      }),
    );
  }
}
