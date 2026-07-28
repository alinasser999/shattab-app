import 'package:batsh/features/briefs/domain/job_feed_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchesSpecialtyFilters', () {
    test('empty selection matches everything', () {
      expect(matchesSpecialtyFilters(['paint'], {}), isTrue);
      expect(matchesSpecialtyFilters([], {}), isTrue);
    });

    test('single selection matches its own trade', () {
      expect(
        matchesSpecialtyFilters(['paint'], {SpecialtyFilter.painting}),
        isTrue,
      );
      expect(
        matchesSpecialtyFilters(['electrical'], {SpecialtyFilter.painting}),
        isFalse,
      );
    });

    // The regression this file exists for: the old if-chain returned on the
    // first *selected* filter, so an electrical brief was excluded whenever
    // painting happened to be selected alongside electrical.
    test('multi-select is a union, not the first selected filter', () {
      final selected = {SpecialtyFilter.painting, SpecialtyFilter.electrical};

      expect(matchesSpecialtyFilters(['paint'], selected), isTrue);
      expect(matchesSpecialtyFilters(['electrical'], selected), isTrue);
      expect(matchesSpecialtyFilters(['plumbing'], selected), isFalse);
    });

    test('order of selection does not change the result', () {
      const brief = ['kitchen'];
      expect(
        matchesSpecialtyFilters(brief, {
          SpecialtyFilter.painting,
          SpecialtyFilter.kitchens,
        }),
        matchesSpecialtyFilters(brief, {
          SpecialtyFilter.kitchens,
          SpecialtyFilter.painting,
        }),
      );
    });

    test('matches Arabic spellings stored on older briefs', () {
      expect(
        matchesSpecialtyFilters(['دهانات'], {SpecialtyFilter.painting}),
        isTrue,
      );
      expect(
        matchesSpecialtyFilters(['كهرباء'], {SpecialtyFilter.electrical}),
        isTrue,
      );
    });

    test('brief with several trades matches on any of them', () {
      expect(
        matchesSpecialtyFilters(
          ['plumbing', 'bathroom'],
          {SpecialtyFilter.bathrooms},
        ),
        isTrue,
      );
    });
  });

  group('SpecialtyFilter.selectedFrom', () {
    test('picks out specialty keys and ignores other filter families', () {
      final selected = SpecialtyFilter.selectedFrom({
        SpecialtyFilter.plumbing.key,
        RecencyFilter.today.key,
        'something:else',
      });

      expect(selected, {SpecialtyFilter.plumbing});
    });

    test('keys are stable and locale-independent', () {
      // Guards against regressing to translated labels as filter identity.
      for (final f in SpecialtyFilter.values) {
        expect(f.key, startsWith('specialty:'));
      }
    });
  });

  group('matchesRecency', () {
    final now = DateTime(2026, 7, 25, 12);

    test('null filter matches everything', () {
      expect(matchesRecency(DateTime(2020), null, now), isTrue);
    });

    test('today accepts the last 24h and rejects older', () {
      expect(
        matchesRecency(
          now.subtract(const Duration(hours: 5)),
          RecencyFilter.today,
          now,
        ),
        isTrue,
      );
      expect(
        matchesRecency(
          now.subtract(const Duration(hours: 30)),
          RecencyFilter.today,
          now,
        ),
        isFalse,
      );
    });

    test('windows widen from today to month', () {
      final tenDaysAgo = now.subtract(const Duration(days: 10));
      expect(matchesRecency(tenDaysAgo, RecencyFilter.today, now), isFalse);
      expect(matchesRecency(tenDaysAgo, RecencyFilter.thisWeek, now), isFalse);
      expect(matchesRecency(tenDaysAgo, RecencyFilter.thisMonth, now), isTrue);
    });

    test('reads a single selected recency key', () {
      expect(
        RecencyFilter.fromKeys({RecencyFilter.thisWeek.key}),
        RecencyFilter.thisWeek,
      );
      expect(RecencyFilter.fromKeys({'specialty:paint'}), isNull);
    });
  });
}
