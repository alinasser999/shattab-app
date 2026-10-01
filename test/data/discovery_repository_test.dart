import 'dart:convert';

import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  test('rating continuation forwards the complete server cursor', () async {
    final requests = <Map<String, dynamic>>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: MockClient((request) async {
        final params = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(params);
        final afterRating = params['p_after_rating'];
        final rows = afterRating == null
            ? [_row('one', 'Alaa', 4.8, 12), _row('two', 'Basma', 4.8, 10)]
            : [_row('three', 'Carim', 4.7, 8), _row('four', 'Dina', 4.6, 7)];
        return http.Response(
          jsonEncode(rows),
          200,
          headers: const {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final repository = DiscoveryRepository(client);
    const filters = DiscoveryFilters(sort: DiscoverySort.rating);

    final first = await repository.fetchContractorsPage(filters, limit: 2);
    final second = await repository.fetchContractorsPage(
      filters,
      limit: 2,
      after: first.cursor,
    );

    expect(requests[0]['p_after_rating'], isNull);
    expect(requests[0]['p_after_rating_count'], isNull);
    expect(requests[1]['p_after_rating'], 4.8);
    expect(requests[1]['p_after_rating_count'], 10);
    expect(requests[1]['p_after_name'], 'Basma');
    expect(requests[1]['p_after_id'], 'two');
    expect(
      second.items.map((item) => item.id),
      isNot(anyOf(contains('one'), contains('two'))),
    );
  });
}

Map<String, dynamic> _row(
  String id,
  String name,
  double rating,
  int ratingCount,
) => {
  'id': id,
  'full_name': name,
  'contractor_profiles': {
    'business_name': name,
    'specialties': const <String>[],
    'service_areas': const <String>[],
    'projects_completed': 1,
    'rating_avg': rating,
    'rating_count': ratingCount,
  },
};
