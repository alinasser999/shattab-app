import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/briefs_repository.dart';
import '../../domain/opportunity_experience.dart';

class OpportunityFiltersNotifier extends Notifier<OpportunityFilters> {
  String get _userKey =>
      ref.read(currentSessionProvider)?.user.id ?? 'signed-out';

  @override
  OpportunityFilters build() {
    ref.watch(currentSessionProvider);
    unawaited(_restore());
    return const OpportunityFilters();
  }

  void setFocus(OpportunityFocus focus) => _set(state.copyWith(focus: focus));

  void setFilters(OpportunityFilters filters) => _set(filters);

  void resetAdvanced() =>
      _set(OpportunityFilters(focus: state.focus, sort: state.sort));

  void reset() => _set(const OpportunityFilters());

  void _set(OpportunityFilters value) {
    state = value;
    unawaited(_persist(value));
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'opportunity_filters_$_userKey';
    if (!ref.mounted) return;
    state = OpportunityFilters(
      focus: _enumByName(
        OpportunityFocus.values,
        prefs.getString('${prefix}_focus'),
      ),
      specialties: prefs.getStringList('${prefix}_specialties')?.toSet() ?? {},
      city: prefs.getString('${prefix}_city'),
      recency: _enumByName(
        OpportunityRecency.values,
        prefs.getString('${prefix}_recency'),
      ),
      hideApplied: prefs.getBool('${prefix}_hide_applied') ?? false,
      sort: _enumByName(
        OpportunitySort.values,
        prefs.getString('${prefix}_sort'),
      ),
    );
  }

  Future<void> _persist(OpportunityFilters value) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'opportunity_filters_$_userKey';
    await Future.wait([
      prefs.setString('${prefix}_focus', value.focus.name),
      prefs.setStringList('${prefix}_specialties', value.specialties.toList()),
      value.city == null
          ? prefs.remove('${prefix}_city')
          : prefs.setString('${prefix}_city', value.city!),
      prefs.setString('${prefix}_recency', value.recency.name),
      prefs.setBool('${prefix}_hide_applied', value.hideApplied),
      prefs.setString('${prefix}_sort', value.sort.name),
    ]);
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return values.first;
}

final opportunityFiltersProvider =
    NotifierProvider<OpportunityFiltersNotifier, OpportunityFilters>(
      OpportunityFiltersNotifier.new,
    );

class OpportunityPaginationState {
  const OpportunityPaginationState({this.isLoading = false, this.error});

  final bool isLoading;
  final Object? error;
}

class OpportunityPaginationNotifier
    extends Notifier<OpportunityPaginationState> {
  @override
  OpportunityPaginationState build() => const OpportunityPaginationState();

  void begin() => state = const OpportunityPaginationState(isLoading: true);

  void complete() => state = const OpportunityPaginationState();

  void fail(Object error) => state = OpportunityPaginationState(error: error);

  void clearError() {
    if (state.error != null) state = const OpportunityPaginationState();
  }
}

final opportunityPaginationProvider =
    NotifierProvider<OpportunityPaginationNotifier, OpportunityPaginationState>(
      OpportunityPaginationNotifier.new,
    );

class OpportunityInteractions {
  const OpportunityInteractions({
    this.savedIds = const {},
    this.viewedIds = const {},
  });

  final Set<String> savedIds;
  final Set<String> viewedIds;

  OpportunityInteractions copyWith({
    Set<String>? savedIds,
    Set<String>? viewedIds,
  }) => OpportunityInteractions(
    savedIds: savedIds ?? this.savedIds,
    viewedIds: viewedIds ?? this.viewedIds,
  );
}

class OpportunityInteractionsNotifier
    extends Notifier<OpportunityInteractions> {
  String get _userKey =>
      ref.read(currentSessionProvider)?.user.id ?? 'signed-out';

  @override
  OpportunityInteractions build() {
    ref.watch(currentSessionProvider);
    unawaited(_restore());
    return const OpportunityInteractions();
  }

  Future<bool> toggleSaved(String briefId) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) throw StateError('authentication_required');

    final previous = state;
    final next = {...state.savedIds};
    final isSaved = !next.remove(briefId);
    if (isSaved) next.add(briefId);
    state = state.copyWith(savedIds: next);
    unawaited(_persist());

    try {
      await ref
          .read(briefsRepositoryProvider)
          .setSavedBrief(
            contractorId: session.user.id,
            briefId: briefId,
            saved: isSaved,
          );
      return isSaved;
    } catch (error) {
      if (ref.mounted) state = previous;
      unawaited(_persist());
      rethrow;
    }
  }

  void markViewed(String briefId) {
    if (state.viewedIds.contains(briefId)) return;
    state = state.copyWith(viewedIds: {...state.viewedIds, briefId});
    unawaited(_persist());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'opportunity_interactions_$_userKey';
    if (!ref.mounted) return;
    state = OpportunityInteractions(
      savedIds: prefs.getStringList('${prefix}_saved')?.toSet() ?? {},
      viewedIds: prefs.getStringList('${prefix}_viewed')?.toSet() ?? {},
    );

    final session = ref.read(currentSessionProvider);
    if (session == null) return;
    try {
      final savedIds = await ref
          .read(briefsRepositoryProvider)
          .fetchSavedBriefIds(session.user.id);
      if (!ref.mounted) return;
      state = state.copyWith(savedIds: savedIds);
      await _persist();
    } catch (_) {
      // Keep the local fallback until the next authenticated restore.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'opportunity_interactions_$_userKey';
    await Future.wait([
      prefs.setStringList('${prefix}_saved', state.savedIds.toList()),
      prefs.setStringList('${prefix}_viewed', state.viewedIds.toList()),
    ]);
  }
}

final opportunityInteractionsProvider =
    NotifierProvider<OpportunityInteractionsNotifier, OpportunityInteractions>(
      OpportunityInteractionsNotifier.new,
    );
