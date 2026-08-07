import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

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

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.colorScheme.primaryContainer,
      child: Text(
        _initials,
        style: BatshTypography.labelSm.copyWith(
          color: context.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
