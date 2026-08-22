import 'package:flutter_test/flutter_test.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';

void main() {
  test('paid placement is parsed without changing earned trust tier', () {
    final listing = ContractorListing.fromJoined({
      'id': 'contractor-1',
      'full_name': 'A contractor',
      'is_sponsored': true,
      'contractor_profiles': {
        'business_name': 'A finishing business',
        'projects_completed': 0,
        'rating_avg': 0,
        'rating_count': 0,
        'verified': false,
        'plan': 'free',
      },
    });

    expect(listing.isSponsored, isTrue);
    expect(listing.isPro, isFalse);
    expect(listing.tier, ContractorTier.bronze);
    expect(listing.rating, isNull);
  });
}
