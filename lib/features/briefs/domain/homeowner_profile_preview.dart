import '../../auth/domain/profile.dart';
import '../../onboarding/domain/onboarding_models.dart';

class PublicHomeownerProfile {
  const PublicHomeownerProfile({required this.profile, required this.details});

  final PublicProfile profile;
  final HomeownerProfile? details;

  factory PublicHomeownerProfile.fromJson(Map<String, dynamic> json) {
    final profileId = json['profile_id'] as String;
    final publicProfile = PublicProfile.fromJson({
      'id': profileId,
      'role': json['role'] as String? ?? 'homeowner',
      'full_name': json['full_name'] as String? ?? '',
      'avatar_url': json['avatar_url'] as String?,
    });

    return PublicHomeownerProfile(
      profile: publicProfile,
      details: HomeownerProfile.fromJson({
        'profile_id': profileId,
        'apartment_type': json['apartment_type'] as String?,
        'city': json['city'] as String?,
        'district': json['district'] as String?,
        'renovation_interests': json['renovation_interests'],
      }),
    );
  }
}
