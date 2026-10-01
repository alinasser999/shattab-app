import 'package:flutter/material.dart';

import '../catalog/specialty_catalog.dart';
import 'l10n_extension.dart';

/// The glyph that stands for a trade.
///
/// Lives beside the labels because it answers the same question about the same
/// catalogue key, and because two screens now draw the trades as icon tiles —
/// the home page's category row and the professional profile's services row. A
/// second copy of this map is a second chance for those two to disagree about
/// what plumbing looks like.
IconData specialtyIcon(String key) =>
    switch (SpecialtyCatalog.rootKeyFor(key)) {
      'full_reno' => Icons.architecture_rounded,
      'design' => Icons.chair_outlined,
      'paint' => Icons.format_paint_outlined,
      'electrical' => Icons.bolt_outlined,
      'plumbing' => Icons.plumbing_outlined,
      'carpentry' => Icons.carpenter_outlined,
      'flooring' => Icons.grid_on_rounded,
      'kitchen' => Icons.countertops_outlined,
      'bathroom' => Icons.bathtub_outlined,
      'plastering' => Icons.format_paint_outlined,
      'gypsum_board' => Icons.view_module_outlined,
      'marble_granite' => Icons.texture_outlined,
      'aluminum_upvc' => Icons.window_outlined,
      'hvac' => Icons.ac_unit_outlined,
      _ => Icons.home_repair_service_outlined,
    };

String localizedSpecialtyLabel(BuildContext context, String key) =>
    switch (SpecialtyCatalog.rootKeyFor(key)) {
      'paint' => context.l10n.specialtyPaint,
      'flooring' => context.l10n.specialtyFlooring,
      'kitchen' => context.l10n.specialtyKitchen,
      'bathroom' => context.l10n.specialtyBathroom,
      'electrical' => context.l10n.specialtyElectrical,
      'plumbing' => context.l10n.specialtyPlumbing,
      'carpentry' => context.l10n.specialtyCarpentry,
      'design' => context.l10n.specialtyDesign,
      'full_reno' => context.l10n.specialtyFullRenovation,
      'plastering' => context.l10n.specialtyPlastering,
      'gypsum_board' => context.l10n.specialtyGypsumBoard,
      'marble_granite' => context.l10n.specialtyMarbleGranite,
      'aluminum_upvc' => context.l10n.specialtyAluminumUpvc,
      'hvac' => context.l10n.specialtyHvac,
      _ => context.l10n.specialtyUnknown,
    };

String localizedSpecialtyChildLabel(BuildContext context, String key) =>
    switch (key.trim()) {
      'flooring:ceramic' => context.l10n.specialtyFlooringCeramic,
      'flooring:porcelain' => context.l10n.specialtyFlooringPorcelain,
      _ => context.l10n.specialtyUnknown,
    };

/// A safe human label for a stored value. Known child values include their
/// localized parent so they remain understandable outside a nested picker.
String localizedSpecialtyDisplayLabel(BuildContext context, String key) {
  final trimmed = key.trim();
  final root = SpecialtyCatalog.rootKeyFor(trimmed);
  if (root != trimmed && SpecialtyCatalog.childrenFor(root).contains(trimmed)) {
    return '${localizedSpecialtyLabel(context, root)} / ${localizedSpecialtyChildLabel(context, trimmed)}';
  }
  return localizedSpecialtyLabel(context, root);
}

/// Localized display text for the fixed onboarding location catalog. The raw
/// Arabic strings remain the values sent to and stored by Supabase.
String localizedOnboardingCityLabel(BuildContext context, String value) =>
    switch (value) {
      'القاهرة' => context.l10n.cityCairo,
      'الجيزة' => context.l10n.cityGiza,
      'القاهرة الجديدة' => context.l10n.cityNewCairo,
      '٦ أكتوبر' => context.l10n.city6October,
      'الإسكندرية' => context.l10n.cityAlexandria,
      _ => value,
    };

String localizedOnboardingDistrictLabel(BuildContext context, String value) =>
    switch (value) {
      'مدينة نصر' => context.l10n.onboardingDistrictNasrCity,
      'مصر الجديدة' => context.l10n.onboardingDistrictHeliopolis,
      'المعادي' => context.l10n.onboardingDistrictMaadi,
      'الزمالك' => context.l10n.onboardingDistrictZamalek,
      'وسط البلد' => context.l10n.onboardingDistrictDowntown,
      'المهندسين' => context.l10n.onboardingDistrictMohandessin,
      'الدقي' => context.l10n.onboardingDistrictDokki,
      'فيصل' => context.l10n.onboardingDistrictFaisal,
      'الهرم' => context.l10n.onboardingDistrictHaram,
      'العجوزة' => context.l10n.onboardingDistrictAgouza,
      'التجمع الأول' => context.l10n.onboardingDistrictFirstSettlement,
      'التجمع الخامس' => context.l10n.onboardingDistrictFifthSettlement,
      'الرحاب' => context.l10n.onboardingDistrictRehab,
      'مدينتي' => context.l10n.onboardingDistrictMadinaty,
      'الحي الأول' => context.l10n.onboardingDistrictFirstDistrict,
      'الحي السابع' => context.l10n.onboardingDistrictSeventhDistrict,
      'حدائق أكتوبر' => context.l10n.onboardingDistrictOctoberGardens,
      'الشيخ زايد' => context.l10n.onboardingDistrictSheikhZayed,
      'سموحة' => context.l10n.onboardingDistrictSmouha,
      'سيدي جابر' => context.l10n.onboardingDistrictSidiGaber,
      'العجمي' => context.l10n.onboardingDistrictAgami,
      'محرم بك' => context.l10n.onboardingDistrictMoharramBek,
      'ميامي' => context.l10n.onboardingDistrictMiami,
      _ => value,
    };
