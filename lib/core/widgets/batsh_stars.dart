import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/theme_extension.dart';

/// Read-only star row for a fractional rating in [0, 5].
class BatshStars extends StatelessWidget {
  const BatshStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
  });

  final double rating;
  final double size;

  /// Fill colour. Null takes the theme's gold, which is what every call site
  /// wanted — a default cannot read the theme, since it must be `const`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? context.colorScheme.tertiary;
    return Semantics(
      label: '${rating.toStringAsFixed(1)} من 5 نجوم',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final filled = i < rating.floor();
          final half = !filled && i == rating.floor() && rating % 1 >= 0.4;
          return Icon(
            half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
            size: size,
            color: filled || half
                ? fill
                : context.colorScheme.surfaceContainerHigh,
          );
        }),
      ),
    );
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
          // Keep the 48dp minimum tap target (WCAG / Material touch size).
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          iconSize: size,
          tooltip: '$star',
          onPressed: () => onChanged(star),
          icon: Icon(
            active ? Icons.star : Icons.star_border,
            color: active
                ? context.colorScheme.tertiary
                : context.colorScheme.onSurfaceVariant,
          ),
        );
      }),
    );
  }
}
