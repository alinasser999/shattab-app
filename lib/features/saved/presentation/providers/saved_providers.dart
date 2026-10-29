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

/// Optimistic override notifier for instant bookmark feedback (Pattern 2).
class SavedOverridesNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void setOverride(String id, bool isSaved) {
    state = {...state, id: isSaved};
  }

  void clearOverride(String id) {
    final next = Map<String, bool>.from(state)..remove(id);
    state = next;
  }
}

final savedOverridesProvider =
    NotifierProvider<SavedOverridesNotifier, Map<String, bool>>(
  SavedOverridesNotifier.new,
);

/// Effective saved contractor IDs combining backend state and optimistic overrides.
final effectiveSavedIdsProvider = Provider<Set<String>>((ref) {
  final base = ref.watch(savedContractorIdsProvider).value ?? const <String>{};
  final overrides = ref.watch(savedOverridesProvider);
  final result = Set<String>.from(base);
  overrides.forEach((id, isSaved) {
    if (isSaved) {
      result.add(id);
    } else {
      result.remove(id);
    }
  });
  return result;
});

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
    final effectiveIds = ref.read(effectiveSavedIdsProvider);
    final currentlySaved = effectiveIds.contains(contractorId);
    final willSave = !currentlySaved;

    // 1. Optimistic update (instant UI reaction)
    ref.read(savedOverridesProvider.notifier).setOverride(contractorId, willSave);

    final repo = ref.read(savedRepositoryProvider);
    try {
      if (currentlySaved) {
        await repo.unsave(
            homeownerId: session.user.id, contractorId: contractorId);
      } else {
        await repo.save(
            homeownerId: session.user.id, contractorId: contractorId);
      }
      ref.invalidate(savedContractorIdsProvider);
      ref.invalidate(savedContractorsProvider);
    } catch (_) {
      // 2. Rollback on failure
      ref.read(savedOverridesProvider.notifier).setOverride(contractorId, currentlySaved);
      rethrow;
    } finally {
      // 3. Clear temporary override once network settles
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(savedOverridesProvider.notifier).clearOverride(contractorId);
      });
    }
  }
}
