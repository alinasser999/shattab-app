import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Curated visual fallbacks for accounts that do not have enough public work.
/// They are presentation-only and never replace data returned by Supabase.
const mockupHeroImage =
    'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1600&q=86';

const mockupPortfolioImages = [
  'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=900&q=86',
  'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=900&q=86',
  'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=900&q=86',
  'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=900&q=86',
  'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=86',
];

class MockupImage extends StatelessWidget {
  const MockupImage({
    super.key,
    this.url,
    this.fit = BoxFit.cover,
    this.memCacheWidth = 900,
  });

  final String? url;
  final BoxFit fit;
  final int memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        borderRadius: BatshRadius.brImage,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          size: 32,
        ),
      ),
    );

    if (url == null || url!.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      memCacheWidth: memCacheWidth,
      fadeInDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : BatshMotion.normal,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class MockupSampleBadge extends StatelessWidget {
  const MockupSampleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.xs,
        vertical: BatshSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, size: 13, color: Colors.white),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            context.l10n.sampleImagesLabel,
            style: BatshTypography.labelSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
