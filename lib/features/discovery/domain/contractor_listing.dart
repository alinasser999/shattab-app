/// Joined view of a contractor — `profiles` row + `contractor_profiles` row.
class ContractorListing {
  const ContractorListing({
    required this.id,
    required this.fullName,
    required this.businessName,
    required this.phone,
    required this.specialties,
    required this.serviceAreas,
    required this.projectsCompleted,
    required this.responseRate,
    this.bio,
    this.logoUrl,
    this.coverPhotoUrl,
    this.headline,
    this.yearsExperience,
  });

  final String id;
  final String fullName;
  final String businessName;
  final String phone;
  final List<String> specialties;
  final List<String> serviceAreas;
  final int projectsCompleted;
  final int responseRate;
  final String? bio;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final String? headline;
  final int? yearsExperience;

  /// Computed star score in [0,5] derived from response rate + project volume.
  /// Placeholder until real reviews land (M4).
  double get computedRating {
    final base = 4.4 + (responseRate - 90).clamp(0, 10) / 100;
    final projectsBoost = (projectsCompleted / 200).clamp(0, 0.4);
    return (base + projectsBoost).clamp(3.8, 5.0);
  }

  factory ContractorListing.fromJoined(Map<String, dynamic> json) {
    final cp = (json['contractor_profiles'] as List?)?.firstOrNull
        as Map<String, dynamic>?;
    return ContractorListing(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      businessName: (cp?['business_name'] as String?) ?? '',
      bio: cp?['bio'] as String?,
      logoUrl: cp?['logo_url'] as String?,
      coverPhotoUrl: cp?['cover_photo_url'] as String?,
      headline: cp?['headline'] as String?,
      specialties: ((cp?['specialties'] as List?) ?? const []).cast<String>(),
      serviceAreas: ((cp?['service_areas'] as List?) ?? const []).cast<String>(),
      yearsExperience: cp?['years_experience'] as int?,
      projectsCompleted: (cp?['projects_completed'] as int?) ?? 0,
      responseRate: (cp?['response_rate'] as int?) ?? 100,
    );
  }
}
