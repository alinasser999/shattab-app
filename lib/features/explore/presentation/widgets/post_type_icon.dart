import 'package:flutter/material.dart';

import '../../domain/post.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class PostTypeIcon extends StatelessWidget {
  const PostTypeIcon({
    super.key,
    required this.postType,
    this.isQuestion = false,
    this.size = 14,
  });

  final PostType postType;
  final bool isQuestion;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: size, color: context.colorScheme.onSurfaceVariant);
  }

  IconData get _icon {
    if (isQuestion) return Icons.help_outline_rounded;

    switch (postType) {
      case PostType.projectShowcase:
        return Icons.visibility;
      case PostType.tip:
        return Icons.lightbulb_outline;
      case PostType.milestone:
        return Icons.emoji_events_outlined;
      case PostType.renovationUpdate:
        return Icons.construction_outlined;
    }
  }
}
