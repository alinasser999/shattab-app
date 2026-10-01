// Canonical contracts used by the assistant boundary.
//
// The assistant may understand Egyptian-Arabic synonyms, but it can only
// return values that already exist in Shattab's marketplace catalogues.

import 'package:batsh/core/catalog/specialty_catalog.dart' as core_catalog;
import 'package:batsh/core/router/routes.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';

abstract final class SpecialtyCatalog {
  /// Root keys shared with discovery, onboarding, and profile forms.
  static final Set<String> canonicalSpecialties = {
    for (final definition in core_catalog.SpecialtyCatalog.roots)
      definition.key,
  };

  /// Cities shared with homeowner onboarding. The assistant does not create
  /// a second city list that can drift from the marketplace.
  static final Set<String> canonicalCities = {
    for (final entry in OnboardingCatalog.citiesAndDistricts) entry.city,
  };

  static const Set<String> allowlistedHelpActions = {
    'browse_contractors',
    'post_brief',
    'my_requests',
    'view_portfolio',
    'pricing_info',
    'contact_support',
  };

  // These labels are only a fallback for non-UI consumers. UI code should use
  // localizedSpecialtyLabel() so English and Arabic stay in sync.
  static const Map<String, String> specialtyArabicLabels = {
    'paint': 'دهانات',
    'flooring': 'أرضيات',
    'kitchen': 'مطابخ',
    'bathroom': 'حمامات',
    'electrical': 'كهرباء',
    'plumbing': 'سباكة',
    'carpentry': 'نجارة',
    'design': 'تصميم داخلي',
    'full_reno': 'تشطيب كامل',
    'plastering': 'محارة',
    'gypsum_board': 'جبس بورد',
    'marble_granite': 'رخام وجرانيت',
    'aluminum_upvc': 'ألوميتال وUPVC',
    'hvac': 'تكييفات',
  };

  static const Map<String, String> specialtySynonyms = {
    'دهان': 'paint',
    'دهانات': 'paint',
    'نقاش': 'paint',
    'نقاشة': 'paint',
    'بياض': 'paint',
    'أرضيات': 'flooring',
    'ارضيات': 'flooring',
    'سيراميك': 'flooring',
    'بورسلين': 'flooring',
    'باركية': 'flooring',
    'باركيه': 'flooring',
    'مطبخ': 'kitchen',
    'مطابخ': 'kitchen',
    'حمام': 'bathroom',
    'حمامات': 'bathroom',
    'صحي': 'bathroom',
    'سباكة': 'plumbing',
    'سباك': 'plumbing',
    'كهرباء': 'electrical',
    'كهربائي': 'electrical',
    'نجارة': 'carpentry',
    'نجار': 'carpentry',
    'أبواب': 'carpentry',
    'شبابيك': 'carpentry',
    'تصميم': 'design',
    'تصميم داخلي': 'design',
    'ديكور': 'design',
    'مهندس ديكور': 'design',
    'تشطيب': 'full_reno',
    'تشطيب كامل': 'full_reno',
    'عمارة': 'full_reno',
    'محارة': 'plastering',
    'لياسة': 'plastering',
    'جبس': 'gypsum_board',
    'جبس بورد': 'gypsum_board',
    'رخام': 'marble_granite',
    'جرانيت': 'marble_granite',
    'رخام وجرانيت': 'marble_granite',
    'ألوميتال': 'aluminum_upvc',
    'الوميتال': 'aluminum_upvc',
    'upvc': 'aluminum_upvc',
    'شتر': 'aluminum_upvc',
    'تكييف': 'hvac',
    'تكييفات': 'hvac',
    'تكييف مركزي': 'hvac',
  };

  static const Map<String, String> citySynonyms = {
    'قاهرة': 'القاهرة',
    'القاهره': 'القاهرة',
    'cairo': 'القاهرة',
    'جيزة': 'الجيزة',
    'الجيزه': 'الجيزة',
    'giza': 'الجيزة',
    'التجمع': 'القاهرة الجديدة',
    'التجمع الخامس': 'القاهرة الجديدة',
    'القاهرة الجديده': 'القاهرة الجديدة',
    'new cairo': 'القاهرة الجديدة',
    '6 اكتوبر': '٦ أكتوبر',
    '٦ اكتوبر': '٦ أكتوبر',
    'اكتوبر': '٦ أكتوبر',
    'الشيخ زايد': '٦ أكتوبر',
    'زايد': '٦ أكتوبر',
    'october': '٦ أكتوبر',
    'اسكندرية': 'الإسكندرية',
    'الإسكندريه': 'الإسكندرية',
    'اسكندريه': 'الإسكندرية',
    'alexandria': 'الإسكندرية',
  };

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Resolves a model/user value to a known root key, or null.
  static String? canonicalizeSpecialty(String? raw) {
    if (raw == null) return null;
    final value = _normalize(raw);
    if (canonicalSpecialties.contains(value)) return value;
    return specialtySynonyms[value];
  }

  /// Resolves a model/user value to a known onboarding city, or null.
  static String? canonicalizeCity(String? raw) {
    if (raw == null) return null;
    final value = _normalize(raw);
    if (canonicalCities.contains(value)) return value;
    return citySynonyms[value];
  }

  static String? canonicalizeHelpAction(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    return allowlistedHelpActions.contains(value) ? value : null;
  }

  /// Maps only known actions to existing routes. Role-specific actions are
  /// never exposed on the wrong portal.
  static String? resolveHelpActionRoute(
    String? actionId, {
    bool isHomeowner = true,
  }) {
    return switch (actionId) {
      'browse_contractors' => isHomeowner ? Routes.homeownerDiscover : null,
      'post_brief' => isHomeowner ? Routes.homeownerNewPost : null,
      'my_requests' => isHomeowner ? Routes.homeownerRequests : null,
      'view_portfolio' =>
        isHomeowner
            ? Routes.homeownerCompletedWork
            : Routes.contractorPortfolio,
      'pricing_info' => Routes.pro,
      _ => null,
    };
  }

  static String labelForSpecialty(String key) =>
      specialtyArabicLabels[core_catalog.SpecialtyCatalog.rootKeyFor(key)] ??
      key;
}
