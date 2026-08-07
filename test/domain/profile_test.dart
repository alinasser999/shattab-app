import 'package:batsh/features/auth/domain/profile.dart';
import 'package:batsh/features/briefs/domain/homeowner_profile_preview.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public homeowner preview ignores contact fields', () {
    final preview = PublicHomeownerProfile.fromJson({
      'profile_id': 'homeowner-1',
      'role': 'homeowner',
      'full_name': 'صاحب الطلب',
      'avatar_url': 'https://example.com/avatar.jpg',
      'phone': '+201000000000',
      'apartment_type': 'two_bedroom',
      'city': 'القاهرة',
      'district': 'المعادي',
      'renovation_interests': ['paint', 'flooring'],
    });

    expect(preview.profile.id, 'homeowner-1');
    expect(preview.profile.role, UserRole.homeowner);
    expect(preview.profile.fullName, 'صاحب الطلب');
    expect(preview.details?.apartmentType, ApartmentType.twoBedroom);
    expect(preview.details?.city, 'القاهرة');
    expect(preview.details?.renovationInterests, ['paint', 'flooring']);
  });

  group('Profile.fromJson', () {
    test('produces correct fields from a valid JSON map', () {
      final json = <String, dynamic>{
        'id': 'user-1',
        'role': 'contractor',
        'full_name': 'مقاول',
        'phone': '+201001234567',
        'onboarding_complete': true,
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-1');
      expect(profile.role, UserRole.contractor);
      expect(profile.fullName, 'مقاول');
      expect(profile.phone, '+201001234567');
      expect(profile.onboardingComplete, true);
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('handles missing optional fields with defaults', () {
      final json = <String, dynamic>{'id': 'user-2', 'role': 'homeowner'};

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-2');
      expect(profile.role, UserRole.homeowner);
      expect(profile.fullName, '');
      expect(profile.phone, '');
      expect(profile.onboardingComplete, false);
      expect(profile.avatarUrl, isNull);
    });

    test('falls back to homeowner for unknown role', () {
      final json = <String, dynamic>{'id': 'user-3', 'role': 'unknown'};

      final profile = Profile.fromJson(json);

      expect(profile.role, UserRole.homeowner);
    });
  });

  group('Profile.copyWith', () {
    test('returns same instance when no arguments', () {
      final profile = createTestProfile();
      final copy = profile.copyWith();

      expect(copy.id, profile.id);
      expect(copy.fullName, profile.fullName);
      expect(copy.role, profile.role);
      expect(copy.phone, profile.phone);
      expect(copy.onboardingComplete, profile.onboardingComplete);
      expect(copy.avatarUrl, profile.avatarUrl);
    });

    test('produces expected changes when fields are overridden', () {
      final profile = createTestProfile();
      final copy = profile.copyWith(
        fullName: 'اسم جديد',
        role: UserRole.contractor,
        onboardingComplete: false,
        avatarUrl: 'https://example.com/new.jpg',
      );

      expect(copy.fullName, 'اسم جديد');
      expect(copy.role, UserRole.contractor);
      expect(copy.onboardingComplete, false);
      expect(copy.avatarUrl, 'https://example.com/new.jpg');
      expect(copy.id, profile.id);
      expect(copy.phone, profile.phone);
    });

    test('keeps original values when copying with null fields', () {
      final profile = createTestProfile(
        fullName: 'اسم أصلي',
        avatarUrl: 'https://example.com/original.jpg',
      );
      final copy = profile.copyWith(fullName: null, avatarUrl: null);

      expect(copy.fullName, 'اسم أصلي');
      expect(copy.avatarUrl, 'https://example.com/original.jpg');
    });
  });
}

/// Minimal factory for use within this test file.
Profile createTestProfile({
  String id = 'test-id',
  UserRole role = UserRole.homeowner,
  String fullName = 'أحمد',
  String phone = '+201000000000',
  bool onboardingComplete = true,
  String? avatarUrl,
}) => Profile(
  id: id,
  role: role,
  fullName: fullName,
  phone: phone,
  onboardingComplete: onboardingComplete,
  avatarUrl: avatarUrl,
);
