import 'package:flutter/material.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshSuccessCheckmark extends StatelessWidget {
  const BatshSuccessCheckmark({super.key, this.size = 80, this.message});
  final double size;
  final String? message;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: context.colorScheme.successContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: size * .55,
            color: context.colorScheme.success,
          ),
        ),
      ),
      if (message != null) ...[
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    ],
  );
}
