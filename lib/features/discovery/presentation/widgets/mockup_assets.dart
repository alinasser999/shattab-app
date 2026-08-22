import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/cache/media_cache.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/image_url.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Curated visual fallbacks for accounts that do not have enough public work.
/// They are presentation-only and never replace data returned by Supabase.
const mockupHeroImage =
    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1600&q=88';

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

    if (!isDisplayableImageUrl(url)) return fallback;

    return CachedNetworkImage(
      // Asks the server for the size actually being drawn. Inert until
      // Supabase image transforms are enabled on the plan, at which point
      // every caller below stops pulling a 1600px upload for a 68px tile
      // without any of them changing.
      imageUrl: sizedImageUrl(url!, width: memCacheWidth),
      // The app's own store rather than the 200-object default.
      cacheManager: mediaCacheManager,
      fit: fit,
      memCacheWidth: memCacheWidth,
      // Downscale once, on the way to disk, instead of decoding the full
      // original on every rebuild. memCacheWidth alone bounds the decode but
      // still keeps the original bytes on disk to re-decode from.
      maxWidthDiskCache: memCacheWidth,
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
          // The badge floats over a photograph whose width belongs to whatever
          // card it lands in — as narrow as half a card on the home page. At a
          // large text scale the label outgrows that slot, so it has to be
          // allowed to shrink. The Row still hugs its content at the default
          // scale, so nothing moves.
          Flexible(
            child: Text(
              context.l10n.sampleImagesLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
