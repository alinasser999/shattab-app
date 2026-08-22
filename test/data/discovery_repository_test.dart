import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discovery cursor carries a total ordering tuple', () {
    const cursor = DiscoveryCursor(
      id: 'contractor-2',
      fullName: 'Alaa',
      matchRank: 0,
      rating: 4.8,
      ratingCount: 12,
    );

    expect(cursor.id, 'contractor-2');
    expect(cursor.fullName, 'Alaa');
    expect(cursor.matchRank, 0);
    expect(cursor.rating, 4.8);
    expect(cursor.ratingCount, 12);
  });

  test('page exhaustion uses the requested page size', () {
    const listing = ContractorListing(
      id: 'contractor-1',
      fullName: 'Alaa',
      businessName: 'Alaa Finishes',
      specialties: [],
      serviceAreas: [],
      projectsCompleted: 0,
    );

    expect(
      DiscoveryPage(
        items: [listing, listing],
        cursor: null,
        requestedLimit: 2,
      ).hasMore,
      isTrue,
    );
    expect(
      DiscoveryPage(
        items: [listing, listing],
        cursor: null,
        requestedLimit: 3,
      ).hasMore,
      isFalse,
    );
  });
}
