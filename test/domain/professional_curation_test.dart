import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/domain/professional_curation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ContractorListing listing({
    required String id,
    bool cover = true,
    bool verified = false,
    int reviews = 0,
    double average = 0,
    int projects = 0,
    List<String> areas = const [],
  }) => ContractorListing(
    id: id,
    fullName: id,
    businessName: '',
    phone: '',
    specialties: const [],
    serviceAreas: areas,
    projectsCompleted: projects,
    coverPhotoUrl: cover ? 'https://example.com/$id.jpg' : null,
    verified: verified,
    reviewCount: reviews,
    reviewAvg: average,
  );

  test('featured professional requires photography and uses real signals', () {
    final selected = pickFeaturedProfessional([
      listing(
        id: 'no-cover',
        cover: false,
        verified: true,
        reviews: 20,
        average: 5,
      ),
      listing(id: 'new', projects: 1),
      listing(
        id: 'trusted',
        verified: true,
        reviews: 8,
        average: 4.8,
        projects: 12,
      ),
    ]);

    expect(selected?.id, 'trusted');
  });

  test('top rated excludes professionals without real reviews', () {
    final ranked = rankTopRated([
      listing(id: 'new', projects: 50),
      listing(id: 'many', reviews: 20, average: 4.8),
      listing(id: 'few', reviews: 1, average: 4.8),
    ]);

    expect(ranked.map((item) => item.id), ['many', 'few']);
  });

  test('nearby ranking never includes professionals outside the city', () {
    final ranked = rankNearbyProfessionals([
      listing(id: 'outside', areas: const ['الجيزة'], reviews: 10, average: 5),
      listing(id: 'local', areas: const ['القاهرة'], verified: true),
    ], 'القاهرة');

    expect(ranked.map((item) => item.id), ['local']);
  });
}
