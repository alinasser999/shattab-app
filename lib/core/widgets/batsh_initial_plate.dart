import 'package:flutter/material.dart';

import '../theme/batsh_typography.dart';
import '../theme/theme_extension.dart';

/// Stands in for a photo that does not exist.
///
/// The previous fallback was a terracotta-to-gold gradient and nothing else,
/// which reads the way any bare gradient in a photo slot reads: the image
/// failed to load. Most contractors have no cover yet, so that fallback is
/// what the app mostly looks like, and it made a populated catalogue look
/// broken.
///
/// A plate carrying the business's own initial reads as a decision instead.
/// The tone is picked from the name, so a given contractor keeps the same
/// plate across the feed, their profile, and search — consistency is what
/// separates "designed placeholder" from "random colour".
class BatshInitialPlate extends StatelessWidget {
  const BatshInitialPlate({super.key, this.name});

  /// Business or person name. The first character becomes the mark. When null
  /// or blank the plate still renders, just without a letter — a calm surface
  /// beats a gradient even with nothing to say.
  final String? name;

  /// Three tones drawn from the brand family. Every one is a `*Container`
  /// role, so the plate follows the active theme rather than pinning a
  /// light-mode colour the way the raw gradient did.
  static (Color, Color) _tone(BuildContext context, String? name) {
    final scheme = context.colorScheme;
    final pairs = [
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    ];
    if (name == null || name.trim().isEmpty) return pairs.first;
    // Stable across rebuilds and across screens: the same name always lands on
    // the same tone. `hashCode` holds within a run, and the grouping only has
    // to be self-consistent, not durable across releases.
    return pairs[name.trim().hashCode.abs() % pairs.length];
  }

  /// First character of the name, taken by rune so a non-BMP glyph does not
  /// come back as half a code unit.
  static String? _initial(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return String.fromCharCode(trimmed.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    final (background, ink) = _tone(context, name);
    final initial = _initial(name);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the mark to the plate rather than fixing a size: this widget
        // fills a 4:3 card cover, a circular avatar, and a portfolio tile.
        final shortest = constraints.biggest.shortestSide;
        final fontSize = (shortest.isFinite ? shortest : 96) * 0.42;

        return ColoredBox(
          color: background,
          child: initial == null
              ? const SizedBox.expand()
              : Center(
                  child: Text(
                    initial,
                    textAlign: TextAlign.center,
                    style: BatshTypography.displayLg.copyWith(
                      fontSize: fontSize,
                      // Sits back rather than announcing itself. The mark is
                      // there to make the plate feel authored, not to be read.
                      color: ink.withValues(alpha: 0.32),
                      height: 1.0,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
