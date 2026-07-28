import 'package:batsh/features/briefs/data/briefs_repository.dart';
import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeLikePattern', () {
    test('returns null for blank input', () {
      expect(BriefsRepository.sanitizeLikePattern(null), isNull);
      expect(BriefsRepository.sanitizeLikePattern(''), isNull);
      expect(BriefsRepository.sanitizeLikePattern('   '), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(BriefsRepository.sanitizeLikePattern('  دهان  '), 'دهان');
    });

    // Without this, typing "%" turns `ilike '%$q%'` into a match-everything
    // pattern, and "_" silently matches any single character.
    test('strips LIKE wildcards so a query cannot match everything', () {
      expect(BriefsRepository.sanitizeLikePattern('%'), isNull);
      expect(BriefsRepository.sanitizeLikePattern('_'), isNull);
      expect(BriefsRepository.sanitizeLikePattern('*'), isNull);
      expect(BriefsRepository.sanitizeLikePattern('%%%'), isNull);
    });

    test('keeps the real words when wildcards are mixed in', () {
      expect(BriefsRepository.sanitizeLikePattern('دهان%'), 'دهان');
      expect(BriefsRepository.sanitizeLikePattern('paint_job'), 'paint job');
    });

    test('leaves ordinary Arabic and Latin text untouched', () {
      expect(BriefsRepository.sanitizeLikePattern('تشطيب شقة'), 'تشطيب شقة');
      expect(BriefsRepository.sanitizeLikePattern('full reno'), 'full reno');
    });
  });

  group('BriefCursor', () {
    test('carries the brief sort tuple', () {
      final brief = Brief(
        id: 'b1',
        homeownerId: 'h1',
        apartmentType: ApartmentType.studio,
        city: 'القاهرة',
        workDescription: 'دهان',
        photoUrls: const [],
        targetSpecialties: const ['paint'],
        status: BriefStatus.open,
        createdAt: DateTime.utc(2026, 7, 25, 9, 30),
      );

      final cursor = BriefCursor.fromBrief(brief);

      expect(cursor.id, 'b1');
      expect(cursor.createdAt, DateTime.utc(2026, 7, 25, 9, 30));
    });
  });
}
