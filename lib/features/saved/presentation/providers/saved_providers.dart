import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../discovery/domain/contractor_listing.dart';
import '../../data/saved_repository.dart';

part 'saved_providers.g.dart';

@riverpod
Future<Set<String>> savedContractorIds(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return <String>{};
  return ref.watch(savedRepositoryProvider).fetchSavedIds(session.user.id);
}

@riverpod
Future<List<ContractorListing>> savedContractors(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const [];
  return ref
      .watch(savedRepositoryProvider)
      .fetchSavedListings(session.user.id);
}

@riverpod
class SavedController extends _$SavedController {
  @override
  void build() {}

  Future<void> toggle(String contractorId) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) return;
    final ids =
        await ref.read(savedContractorIdsProvider.future);
    final repo = ref.read(savedRepositoryProvider);
    if (ids.contains(contractorId)) {
      await repo.unsave(
          homeownerId: session.user.id, contractorId: contractorId);
    } else {
      await repo.save(
          homeownerId: session.user.id, contractorId: contractorId);
    }
    ref.invalidate(savedContractorIdsProvider);
    ref.invalidate(savedContractorsProvider);
  }
}
