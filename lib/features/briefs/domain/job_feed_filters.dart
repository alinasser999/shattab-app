/// Quick-filter model for the contractor opportunities feed.
///
/// Filter identity is a stable, locale-independent key. The UI previously
/// stored the translated label as the value, which meant a language switch
/// orphaned every active selection and made matching depend on display copy.
library;

/// A specialty quick-filter and the substrings that identify it inside a
/// brief's `target_specialties`.
///
/// Briefs store catalog keys (`'paint'`), but older rows and free-text entries
/// can hold Arabic, so each filter carries both spellings.
enum SpecialtyFilter {
  painting('specialty:paint', ['paint', 'دهان']),
  electrical('specialty:electrical', ['electrical', 'كهرب']),
  plumbing('specialty:plumbing', ['plumbing', 'سباك']),
  finishing('specialty:full_reno', ['full_reno', 'تشطيب']),
  bathrooms('specialty:bathroom', ['bathroom', 'حمام']),
  kitchens('specialty:kitchen', ['kitchen', 'مطب']);

  const SpecialtyFilter(this.key, this.tokens);

  /// Stable value stored in the active-filter set.
  final String key;

  /// Substrings that mark a brief specialty as belonging to this filter.
  final List<String> tokens;

  static SpecialtyFilter? fromKey(String key) {
    for (final f in SpecialtyFilter.values) {
      if (f.key == key) return f;
    }
    return null;
  }

  /// The subset of [keys] that are specialty filters.
  static Set<SpecialtyFilter> selectedFrom(Set<String> keys) {
    final out = <SpecialtyFilter>{};
    for (final k in keys) {
      final f = fromKey(k);
      if (f != null) out.add(f);
    }
    return out;
  }
}

/// Recency quick-filter. Single-select in the sheet.
enum RecencyFilter {
  today('time:today', Duration(hours: 24)),
  thisWeek('time:week', Duration(days: 7)),
  thisMonth('time:month', Duration(days: 30));

  const RecencyFilter(this.key, this.window);

  final String key;
  final Duration window;

  static RecencyFilter? fromKeys(Set<String> keys) {
    for (final f in RecencyFilter.values) {
      if (keys.contains(f.key)) return f;
    }
    return null;
  }
}

/// True when [briefSpecialties] satisfies [selected].
///
/// Union semantics: selecting دهانات and كهرباء widens the result to briefs in
/// either trade. An empty selection matches everything.
bool matchesSpecialtyFilters(
  List<String> briefSpecialties,
  Set<SpecialtyFilter> selected,
) {
  if (selected.isEmpty) return true;
  final tokens = {for (final f in selected) ...f.tokens};
  return briefSpecialties.any((s) => tokens.any(s.contains));
}

/// True when [createdAt] falls inside [filter]'s window, measured from [now].
bool matchesRecency(DateTime createdAt, RecencyFilter? filter, DateTime now) {
  if (filter == null) return true;
  return createdAt.isAfter(now.subtract(filter.window));
}
