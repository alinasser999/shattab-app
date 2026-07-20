import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../data/homeowner_profile_repository.dart';

part 'homeowner_profile_providers.g.dart';

// keepAlive: called one-shot via ref.read(...notifier); autoDispose would
// tear the controller down mid-await and its next ref use would throw.
@Riverpod(keepAlive: true)
class HomeownerProfileController extends _$HomeownerProfileController {
  @override
  void build() {}

  Future<void> save({
    required File? newAvatarFile,
    required String fullName,
    ApartmentType? apartmentType,
    String? city,
    String? district,
    List<String>? renovationInterests,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) throw StateError('No session');
    final profileId = session.user.id;
    final repo = ref.read(homeownerProfileRepositoryProvider);

    String? avatarUrl;
    if (newAvatarFile != null) {
      avatarUrl = await repo.uploadAvatar(
        profileId: profileId,
        file: newAvatarFile,
      );
    }

    await repo.updateProfile(
      profileId: profileId,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );

    await repo.upsertHomeownerFields(
      profileId: profileId,
      apartmentType: apartmentType,
      city: city,
      district: district,
      renovationInterests: renovationInterests,
    );

    ref.invalidate(homeownerProfileProvider);
    ref.read(currentProfileProvider.notifier).refresh();
  }
}
