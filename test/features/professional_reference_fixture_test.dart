import 'package:batsh/features/discovery/domain/professional_reference_fixture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'professional reference fixture',
    skip: !professionalReferenceEnabled,
    () {
      test(
        'contains 186 reviews with the exact reference distribution and 4.9 average',
        () {
          final listing = ProfessionalReferenceFixture.noorListing;
          final reviews = ProfessionalReferenceFixture.reviewsForId(listing.id);

          expect(listing.reviewCount, 186);
          expect(reviews, hasLength(186));
          expect(
            {
              for (var stars = 1; stars <= 5; stars++)
                stars: reviews.where((review) => review.rating == stars).length,
            },
            {1: 0, 2: 0, 3: 1, 4: 16, 5: 169},
          );

          final average =
              reviews.fold<int>(0, (total, review) => total + review.rating) /
              reviews.length;
          expect(listing.reviewAvg.toStringAsFixed(1), '4.9');
          expect(average.toStringAsFixed(1), '4.9');
        },
      );

      test('saved IDs are shared in memory and toggle without storage', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final observations = <Set<String>>[];
        final subscription = container.listen(
          professionalReferenceSavedIdsProvider,
          (_, next) => observations.add(next),
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        expect(container.read(professionalReferenceSavedIdsProvider), isEmpty);
        container
            .read(professionalReferenceSavedIdsProvider.notifier)
            .toggle(ProfessionalReferenceFixture.noorId);
        expect(container.read(professionalReferenceSavedIdsProvider), {
          ProfessionalReferenceFixture.noorId,
        });
        expect(observations.last, {ProfessionalReferenceFixture.noorId});

        container
            .read(professionalReferenceSavedIdsProvider.notifier)
            .toggle(ProfessionalReferenceFixture.noorId);
        expect(container.read(professionalReferenceSavedIdsProvider), isEmpty);
        expect(observations.last, isEmpty);

        container
            .read(professionalReferenceSavedIdsProvider.notifier)
            .toggle('ordinary-professional-1');
        expect(container.read(professionalReferenceSavedIdsProvider), isEmpty);
      });
    },
  );
}
