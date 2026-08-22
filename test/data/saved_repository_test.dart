import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/saved/data/saved_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved cursor keeps the timestamp and contractor tie-breaker', () {
    final cursor = SavedCursor.fromRow({
      'id': 'contractor-2',
      'saved_at': '2026-08-14T10:00:00.000Z',
    });

    expect(cursor.contractorId, 'contractor-2');
    expect(cursor.savedAt.toUtc(), DateTime.utc(2026, 8, 14, 10));
  });

  test('saved page exhaustion uses the requested page size', () {
    const listing = ContractorListing(
      id: 'contractor-1',
      fullName: 'Alaa',
      businessName: 'Alaa Finishes',
      specialties: [],
      serviceAreas: [],
      projectsCompleted: 0,
    );

    expect(
      SavedPage(
        items: [listing, listing],
        cursor: null,
        requestedLimit: 2,
      ).hasMore,
      isTrue,
    );
    expect(
      SavedPage(
        items: [listing, listing],
        cursor: null,
        requestedLimit: 3,
      ).hasMore,
      isFalse,
    );
  });
}
