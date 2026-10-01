import 'package:batsh/features/auth/domain/profile.dart';
import 'package:batsh/core/debug/debug_role_override.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profileForDebugRole', () {
    test(
      'keeps a null profile and real role unchanged without an override',
      () {
        final profile = _profile(UserRole.contractor);

        expect(profileForDebugRole(null, UserRole.homeowner), isNull);
        expect(profileForDebugRole(profile, null), same(profile));
        expect(
          profileForDebugRole(profile, UserRole.contractor),
          same(profile),
        );
      },
    );

    test('changes only the view role for a selected debug role', () {
      final profile = _profile(UserRole.contractor);

      final preview = profileForDebugRole(profile, UserRole.homeowner);

      expect(preview, isNotNull);
      expect(preview!.role, UserRole.homeowner);
      expect(preview.id, profile.id);
      expect(preview.fullName, profile.fullName);
      expect(preview.phone, profile.phone);
      expect(preview.onboardingComplete, profile.onboardingComplete);
    });
  });

  test(
    'debug override provider starts empty and can return to the real role',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(debugRoleOverrideProvider), isNull);

      final notifier = container.read(debugRoleOverrideProvider.notifier);
      notifier.set(UserRole.homeowner);
      expect(container.read(debugRoleOverrideProvider), UserRole.homeowner);

      notifier.set(null);
      expect(container.read(debugRoleOverrideProvider), isNull);
    },
  );
}

Profile _profile(UserRole role) => Profile(
  id: 'debug-user',
  role: role,
  fullName: 'Debug User',
  phone: '+201000000000',
  onboardingComplete: true,
);
