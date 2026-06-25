import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../data/briefs_repository.dart';
import '../../domain/brief.dart';

part 'briefs_providers.g.dart';

@riverpod
Future<List<Brief>> myBriefs(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const [];
  return ref.watch(briefsRepositoryProvider).fetchMine(session.user.id);
}

@riverpod
Future<Brief?> briefById(Ref ref, String id) =>
    ref.watch(briefsRepositoryProvider).fetchById(id);

@riverpod
Future<List<Brief>> contractorOpportunities(Ref ref) =>
    ref.watch(briefsRepositoryProvider).fetchOpportunitiesForContractor();

@riverpod
Future<List<Brief>> contractorDirectBriefs(Ref ref) =>
    ref.watch(briefsRepositoryProvider).fetchDirectBriefsForContractor();

class DraftPhoto {
  const DraftPhoto({this.file, this.bytes, this.url});
  final File? file;
  final Uint8List? bytes;
  final String? url;
  bool get isLocal => file != null || bytes != null;
}

@riverpod
class BriefsController extends _$BriefsController {
  @override
  void build() {}

  Future<Brief> createDirectRequest({
    required String contractorId,
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<DraftPhoto> photos,
  }) async {
    return _create(
      targetContractorId: contractorId,
      apartmentType: apartmentType,
      city: city,
      district: district,
      workDescription: workDescription,
      photos: photos,
      targetSpecialties: const [],
    );
  }

  Future<Brief> createPost({
    required ApartmentType apartmentType,
    required String city,
    String? district,
    required String workDescription,
    required List<String> targetSpecialties,
    required List<DraftPhoto> photos,
  }) async {
    return _create(
      targetContractorId: null,
      apartmentType: apartmentType,
      city: city,
      district: district,
      workDescription: workDescription,
      photos: photos,
      targetSpecialties: targetSpecialties,
    );
  }

  Future<Brief> _create({
    required String? targetContractorId,
    required ApartmentType apartmentType,
    required String city,
    required String? district,
    required String workDescription,
    required List<DraftPhoto> photos,
    required List<String> targetSpecialties,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      throw StateError('No session — cannot create brief.');
    }
    final repo = ref.read(briefsRepositoryProvider);

    // Create brief with empty photos first to get an ID for the storage path.
    final brief = await repo.createBrief(
      homeownerId: session.user.id,
      targetContractorId: targetContractorId,
      apartmentType: apartmentType,
      city: city,
      district: district,
      workDescription: workDescription,
      photoUrls: const [],
      targetSpecialties: targetSpecialties,
    );

    if (photos.isNotEmpty) {
      final urls = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final p = photos[i];
        final url = await repo.uploadPhoto(
          homeownerId: session.user.id,
          draftId: brief.id,
          seq: i,
          file: p.file,
          bytes: p.bytes,
        );
        urls.add(url);
      }
      await repo.setPhotoUrls(brief.id, urls);
    }

    ref.invalidate(myBriefsProvider);
    return brief;
  }

  Future<void> cancel(String briefId) async {
    await ref.read(briefsRepositoryProvider).cancelBrief(briefId);
    ref.invalidate(myBriefsProvider);
    ref.invalidate(briefByIdProvider(briefId));
  }
}
