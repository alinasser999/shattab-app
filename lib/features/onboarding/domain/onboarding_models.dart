enum ApartmentType {
  studio,
  oneBedroom,
  twoBedroom,
  threeBedroomPlus,
  duplex,
  villa,
  penthouse;

  static ApartmentType? fromString(String? value) {
    if (value == null) return null;
    for (final v in ApartmentType.values) {
      if (v.dbValue == value) return v;
    }
    return null;
  }

  String get dbValue => switch (this) {
        ApartmentType.studio => 'studio',
        ApartmentType.oneBedroom => 'one_bedroom',
        ApartmentType.twoBedroom => 'two_bedroom',
        ApartmentType.threeBedroomPlus => 'three_bedroom_plus',
        ApartmentType.duplex => 'duplex',
        ApartmentType.villa => 'villa',
        ApartmentType.penthouse => 'penthouse',
      };
}

class HomeownerProfile {
  const HomeownerProfile({
    required this.profileId,
    this.apartmentType,
    this.city,
    this.district,
    this.renovationInterests = const [],
  });

  final String profileId;
  final ApartmentType? apartmentType;
  final String? city;
  final String? district;
  final List<String> renovationInterests;

  bool get hasApartmentType => apartmentType != null;
  bool get hasLocation =>
      (city?.isNotEmpty ?? false) && (district?.isNotEmpty ?? false);
  bool get hasInterests => renovationInterests.isNotEmpty;

  HomeownerProfile copyWith({
    ApartmentType? apartmentType,
    String? city,
    String? district,
    List<String>? renovationInterests,
  }) =>
      HomeownerProfile(
        profileId: profileId,
        apartmentType: apartmentType ?? this.apartmentType,
        city: city ?? this.city,
        district: district ?? this.district,
        renovationInterests: renovationInterests ?? this.renovationInterests,
      );

  factory HomeownerProfile.fromJson(Map<String, dynamic> json) =>
      HomeownerProfile(
        profileId: json['profile_id'] as String,
        apartmentType:
            ApartmentType.fromString(json['apartment_type'] as String?),
        city: json['city'] as String?,
        district: json['district'] as String?,
        renovationInterests:
            ((json['renovation_interests'] as List?) ?? const [])
                .map((e) => e as String).toList(),
      );
}

class ContractorProfile {
  const ContractorProfile({
    required this.profileId,
    this.businessName,
    this.logoUrl,
    this.bio,
    this.specialties = const [],
    this.serviceAreas = const [],
    this.yearsExperience,
  });

  final String profileId;
  final String? businessName;
  final String? logoUrl;
  final String? bio;
  final List<String> specialties;
  final List<String> serviceAreas;
  final int? yearsExperience;

  bool get hasBusinessName =>
      businessName != null && businessName!.trim().isNotEmpty;
  bool get hasSpecialties => specialties.isNotEmpty;
  bool get hasServiceAreas => serviceAreas.isNotEmpty;
  bool get hasExperience => yearsExperience != null;

  ContractorProfile copyWith({
    String? businessName,
    String? logoUrl,
    String? bio,
    List<String>? specialties,
    List<String>? serviceAreas,
    int? yearsExperience,
  }) =>
      ContractorProfile(
        profileId: profileId,
        businessName: businessName ?? this.businessName,
        logoUrl: logoUrl ?? this.logoUrl,
        bio: bio ?? this.bio,
        specialties: specialties ?? this.specialties,
        serviceAreas: serviceAreas ?? this.serviceAreas,
        yearsExperience: yearsExperience ?? this.yearsExperience,
      );

  factory ContractorProfile.fromJson(Map<String, dynamic> json) =>
      ContractorProfile(
        profileId: json['profile_id'] as String,
        businessName: json['business_name'] as String?,
        logoUrl: json['logo_url'] as String?,
        bio: json['bio'] as String?,
        specialties:
            ((json['specialties'] as List?) ?? const []).map((e) => e as String).toList(),
        serviceAreas:
            ((json['service_areas'] as List?) ?? const []).map((e) => e as String).toList(),
        yearsExperience: json['years_experience'] as int?,
      );
}

/// Reference data for onboarding pickers (Arabic display, dbValue is what we persist).
class OnboardingCatalog {
  const OnboardingCatalog._();

  static const List<({String city, List<String> districts})> citiesAndDistricts = [
    (
      city: 'القاهرة',
      districts: ['مدينة نصر', 'مصر الجديدة', 'المعادي', 'الزمالك', 'وسط البلد'],
    ),
    (
      city: 'الجيزة',
      districts: ['المهندسين', 'الدقي', 'فيصل', 'الهرم', 'العجوزة'],
    ),
    (
      city: 'القاهرة الجديدة',
      districts: ['التجمع الأول', 'التجمع الخامس', 'الرحاب', 'مدينتي'],
    ),
    (
      city: '٦ أكتوبر',
      districts: ['الحي الأول', 'الحي السابع', 'حدائق أكتوبر', 'الشيخ زايد'],
    ),
    (
      city: 'الإسكندرية',
      districts: ['سموحة', 'سيدي جابر', 'العجمي', 'محرم بك', 'ميامي'],
    ),
  ];

  static const Map<String, String> interestsCatalog = {
    'paint': 'دهانات',
    'flooring': 'أرضيات',
    'kitchen': 'مطبخ',
    'bathroom': 'حمام',
    'electrical': 'كهرباء',
    'plumbing': 'سباكة',
    'full_reno': 'تشطيب كامل',
  };

  static const Map<String, String> specialtiesCatalog = {
    'paint': 'دهانات',
    'flooring': 'أرضيات',
    'kitchen': 'مطابخ',
    'bathroom': 'حمامات',
    'electrical': 'كهرباء',
    'plumbing': 'سباكة',
    'carpentry': 'نجارة',
    'design': 'تصميم داخلي',
    'full_reno': 'تشطيب كامل',
  };

  static const Map<ApartmentType, String> apartmentLabels = {
    ApartmentType.studio: 'استوديو',
    ApartmentType.oneBedroom: 'غرفة نوم',
    ApartmentType.twoBedroom: 'غرفتين نوم',
    ApartmentType.threeBedroomPlus: '٣ غرف أو أكتر',
    ApartmentType.duplex: 'دوبلكس',
    ApartmentType.villa: 'فيلا',
    ApartmentType.penthouse: 'بنتهاوس',
  };
}
