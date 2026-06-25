import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

import '../theme/batsh_spacing.dart';

extension BuildContextX on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
}

/// Tiny shorthands so feature code stays terse.
class Gaps {
  const Gaps._();

  static const Widget xs = Gap(BatshSpacing.xs);
  static const Widget sm = Gap(BatshSpacing.sm);
  static const Widget md = Gap(BatshSpacing.md);
  static const Widget gutter = Gap(BatshSpacing.gutter);
  static const Widget lg = Gap(BatshSpacing.lg);
  static const Widget xl = Gap(BatshSpacing.xl);
}
