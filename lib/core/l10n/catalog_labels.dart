import 'package:flutter/material.dart';

import 'l10n_extension.dart';

/// The glyph that stands for a trade.
///
/// Lives beside the labels because it answers the same question about the same
/// catalogue key, and because two screens now draw the trades as icon tiles —
/// the home page's category row and the professional profile's services row. A
/// second copy of this map is a second chance for those two to disagree about
/// what plumbing looks like.
IconData specialtyIcon(String key) => switch (key) {
  'full_reno' => Icons.architecture_rounded,
  'design' => Icons.chair_outlined,
  'paint' => Icons.format_paint_outlined,
  'electrical' => Icons.bolt_outlined,
  'plumbing' => Icons.plumbing_outlined,
  'carpentry' => Icons.carpenter_outlined,
  'flooring' => Icons.grid_on_rounded,
  'kitchen' => Icons.countertops_outlined,
  'bathroom' => Icons.bathtub_outlined,
  _ => Icons.home_repair_service_outlined,
};

String localizedSpecialtyLabel(BuildContext context, String key) =>
    switch (key) {
      'paint' => context.l10n.specialtyPaint,
      'flooring' => context.l10n.specialtyFlooring,
      'kitchen' => context.l10n.specialtyKitchen,
      'bathroom' => context.l10n.specialtyBathroom,
      'electrical' => context.l10n.specialtyElectrical,
      'plumbing' => context.l10n.specialtyPlumbing,
      'carpentry' => context.l10n.specialtyCarpentry,
      'design' => context.l10n.specialtyDesign,
      'full_reno' => context.l10n.specialtyFullRenovation,
      _ => key,
    };
