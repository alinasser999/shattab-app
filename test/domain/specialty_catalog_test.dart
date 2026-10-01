import 'package:batsh/core/catalog/specialty_catalog.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpecialtyCatalog', () {
    test('contains the shared root catalog and flooring details', () {
      final keys = SpecialtyCatalog.roots.map((root) => root.key).toList();

      expect(
        keys,
        containsAll([
          'paint',
          'flooring',
          'plastering',
          'gypsum_board',
          'marble_granite',
          'aluminum_upvc',
          'hvac',
        ]),
      );
      expect(SpecialtyCatalog.childrenFor('flooring'), [
        'flooring:ceramic',
        'flooring:porcelain',
      ]);
    });

    test('puts the primary root before all details and preserves extras', () {
      expect(
        SpecialtyCatalog.normalizeSelection([
          'flooring:porcelain',
          'paint',
          'flooring:ceramic',
          'legacy_trade',
        ]),
        [
          'flooring',
          'paint',
          'flooring:ceramic',
          'flooring:porcelain',
          'legacy_trade',
        ],
      );
    });

    test('can promote an additional root to primary', () {
      expect(
        SpecialtyCatalog.normalizeSelection([
          'paint',
          'flooring:ceramic',
        ], primary: 'flooring'),
        ['flooring', 'paint', 'flooring:ceramic'],
      );
    });

    test('projects children to their parent for matching', () {
      expect(SpecialtyCatalog.rootKeys(['flooring:ceramic']), ['flooring']);
      expect(
        SpecialtyCatalog.matchingKeys(['flooring']),
        containsAll(['flooring', 'flooring:ceramic', 'flooring:porcelain']),
      );
    });
  });

  group('ProviderKind', () {
    test('round-trips the specialized provider wire value', () {
      expect(
        ProviderKind.fromWire('specialized_provider'),
        ProviderKind.specializedProvider,
      );
      expect(ProviderKind.specializedProvider.wire, 'specialized_provider');
      expect(ProviderKind.fromWire('new_kind'), ProviderKind.contractor);
    });
  });

  group('ContractorProfile identity requirements', () {
    test('allows a tradesman to use only a personal name', () {
      const profile = ContractorProfile(
        profileId: 'tradesman-1',
        providerKind: ProviderKind.tradesman,
      );

      expect(profile.hasRequiredIdentity(responsibleName: 'Ahmed'), isTrue);
      expect(profile.hasRequiredIdentity(responsibleName: ''), isFalse);
    });

    test('requires a business name only for the two organization kinds', () {
      for (final kind in [
        ProviderKind.engineeringOffice,
        ProviderKind.finishingCompany,
      ]) {
        final profile = ContractorProfile(
          profileId: kind.wire,
          providerKind: kind,
        );
        expect(profile.requiresBusinessName, isTrue);
        expect(profile.hasRequiredIdentity(responsibleName: 'Mona'), isFalse);
        expect(
          profile
              .copyWith(businessName: 'A business')
              .hasRequiredIdentity(responsibleName: 'Mona'),
          isTrue,
        );
      }
    });

    test('individual and specialist kinds can use a personal name alone', () {
      for (final kind in [
        ProviderKind.contractor,
        ProviderKind.engineer,
        ProviderKind.interiorDesigner,
        ProviderKind.specializedProvider,
        ProviderKind.tradesman,
      ]) {
        final profile = ContractorProfile(
          profileId: kind.wire,
          providerKind: kind,
        );
        expect(profile.requiresBusinessName, isFalse);
        expect(profile.hasRequiredIdentity(responsibleName: 'Mona'), isTrue);
      }
    });
  });

  test('joined listings normalize legacy specialties and provider kind', () {
    final listing = ContractorListing.fromJoined({
      'id': 'office-1',
      'full_name': 'Mona',
      'contractor_profiles': {
        'business_name': 'Air Experts',
        'specialties': ['flooring:porcelain', 'flooring'],
        'service_areas': ['Cairo'],
        'provider_kind': 'specialized_provider',
      },
    });

    expect(listing.specialties, ['flooring', 'flooring:porcelain']);
    expect(listing.providerKind, ProviderKind.specializedProvider);
  });
}
