import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../cache/media_cache.dart';
import '../utils/image_url.dart';
import 'batsh_initial_plate.dart';

class AvatarWithInitials extends StatelessWidget {
  const AvatarWithInitials({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 18,
  });

  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (isDisplayableImageUrl(url)) {
      final cacheWidth = (radius * 6).round();
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: CachedNetworkImage(
            imageUrl: sizedImageUrl(url!, width: cacheWidth),
            cacheManager: mediaCacheManager,
            fit: BoxFit.cover,
            memCacheWidth: cacheWidth,
            placeholder: (_, _) => _FallbackAvatar(name: name, radius: radius),
            errorWidget: (_, _, _) =>
                _FallbackAvatar(name: name, radius: radius),
          ),
        ),
      );
    }
    return _FallbackAvatar(name: name, radius: radius);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: BatshInitialPlate(name: name),
      ),
    );
  }
}
