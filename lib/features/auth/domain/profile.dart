enum UserRole {
  homeowner,
  contractor;

  static UserRole fromString(String value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => UserRole.homeowner,
      );
}

class Profile {
  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.onboardingComplete,
    this.avatarUrl,
  });

  final String id;
  final UserRole role;
  final String fullName;
  final String phone;
  final bool onboardingComplete;
  final String? avatarUrl;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        role: UserRole.fromString(json['role'] as String),
        fullName: (json['full_name'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        onboardingComplete: (json['onboarding_complete'] as bool?) ?? false,
        avatarUrl: json['avatar_url'] as String?,
      );

  Profile copyWith({
    String? fullName,
    UserRole? role,
    bool? onboardingComplete,
    String? avatarUrl,
  }) =>
      Profile(
        id: id,
        role: role ?? this.role,
        fullName: fullName ?? this.fullName,
        phone: phone,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
