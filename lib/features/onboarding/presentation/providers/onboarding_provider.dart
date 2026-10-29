import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/onboarding_repository.dart';
import '../../domain/onboarding_models.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: true)
Future<HomeownerProfile?> homeownerProfile(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;
  return ref.watch(onboardingRepositoryProvider).fetchHomeowner(session.user.id);
}

@Riverpod(keepAlive: true)
Future<ContractorProfile?> contractorProfile(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;
  return ref
      .watch(onboardingRepositoryProvider)
      .fetchContractor(session.user.id);
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  void build() {}

  String _requireUserId() {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      throw StateError('No session — cannot mutate onboarding state.');
    }
    return session.user.id;
  }

  Future<void> selectRole(UserRole role, String fullName) async {
    final userId = _requireUserId();
    await ref.read(authRepositoryProvider).updateRole(
          userId: userId,
          role: role,
          fullName: fullName,
        );
    await ref.read(currentProfileProvider.notifier).refresh();
  }

  Future<void> setApartmentType(ApartmentType type) async {
    await ref
        .read(onboardingRepositoryProvider)
        .upsertHomeowner(profileId: _requireUserId(), apartmentType: type);
    ref.invalidate(homeownerProfileProvider);
  }

  Future<void> setHomeownerLocation({
    required String city,
    required String district,
  }) async {
    await ref.read(onboardingRepositoryProvider).upsertHomeowner(
          profileId: _requireUserId(),
          city: city,
          district: district,
        );
    ref.invalidate(homeownerProfileProvider);
  }

  Future<void> setHomeownerInterests(List<String> interests) async {
    await ref.read(onboardingRepositoryProvider).upsertHomeowner(
          profileId: _requireUserId(),
          renovationInterests: interests,
        );
    ref.invalidate(homeownerProfileProvider);
  }

  Future<void> setBusinessName({
    required String businessName,
    required String displayName,
  }) async {
    final userId = _requireUserId();
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.upsertContractor(
      profileId: userId,
      businessName: businessName,
    );
    await repo.updateFullName(profileId: userId, fullName: displayName);
    ref.invalidate(contractorProfileProvider);
    await ref.read(currentProfileProvider.notifier).refresh();
  }

  Future<void> setSpecialties(List<String> specialties) async {
    await ref.read(onboardingRepositoryProvider).upsertContractor(
          profileId: _requireUserId(),
          specialties: specialties,
        );
    ref.invalidate(contractorProfileProvider);
  }

  Future<void> setServiceAreas(List<String> serviceAreas) async {
    await ref.read(onboardingRepositoryProvider).upsertContractor(
          profileId: _requireUserId(),
          serviceAreas: serviceAreas,
        );
    ref.invalidate(contractorProfileProvider);
  }

  Future<String?> uploadLogo(File file) async {
    if (kIsWeb) throw UnsupportedError('File upload not supported on web');
    final userId = _requireUserId();
    final repo = ref.read(onboardingRepositoryProvider);
    final url = await repo.uploadContractorLogo(profileId: userId, file: file);
    await repo.upsertContractor(profileId: userId, logoUrl: url);
    ref.invalidate(contractorProfileProvider);
    return url;
  }

  Future<void> setExperienceAndBio({
    required int yearsExperience,
    required String bio,
  }) async {
    await ref.read(onboardingRepositoryProvider).upsertContractor(
          profileId: _requireUserId(),
          yearsExperience: yearsExperience,
          bio: bio,
        );
    ref.invalidate(contractorProfileProvider);
  }

  /// Edit-profile save: update showcase text fields in one upsert.
  /// Pass only the fields being changed; nulls are skipped by the repo.
  Future<void> saveShowcase({
    String? businessName,
    String? headline,
    String? bio,
    int? yearsExperience,
  }) async {
    await ref.read(onboardingRepositoryProvider).upsertContractor(
          profileId: _requireUserId(),
          businessName: businessName,
          headline: headline,
          bio: bio,
          yearsExperience: yearsExperience,
        );
    ref.invalidate(contractorProfileProvider);
  }

  Future<String?> uploadCover(File file) async {
    if (kIsWeb) throw UnsupportedError('File upload not supported on web');
    final userId = _requireUserId();
    final repo = ref.read(onboardingRepositoryProvider);
    final url = await repo.uploadContractorCover(profileId: userId, file: file);
    await repo.upsertContractor(profileId: userId, coverPhotoUrl: url);
    ref.invalidate(contractorProfileProvider);
    return url;
  }

  Future<void> markComplete() async {
    final userId = _requireUserId();
    await ref.read(onboardingRepositoryProvider).markOnboardingComplete(userId);
    await ref.read(currentProfileProvider.notifier).refresh();
  }
}
