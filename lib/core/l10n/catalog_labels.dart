import 'package:flutter/material.dart';

import 'l10n_extension.dart';

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
