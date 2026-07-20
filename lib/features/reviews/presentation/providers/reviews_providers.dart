import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../data/reviews_repository.dart';
import '../../domain/review.dart';

part 'reviews_providers.g.dart';

/// The review on a single brief (null until the homeowner posts one).
@riverpod
Future<Review?> reviewForBrief(Ref ref, String briefId) =>
    ref.watch(reviewsRepositoryProvider).fetchForBrief(briefId);

/// All reviews a contractor has received.
@riverpod
Future<List<Review>> reviewsForContractor(Ref ref, String contractorId) =>
    ref.watch(reviewsRepositoryProvider).fetchForContractor(contractorId);

// keepAlive: called one-shot via ref.read(...notifier); autoDispose would
// tear the controller down mid-await and its next ref use would throw.
@Riverpod(keepAlive: true)
class ReviewController extends _$ReviewController {
  @override
  void build() {}

  Future<void> submit({
    required String briefId,
    required String contractorId,
    required int rating,
    String? comment,
  }) async {
    await ref.read(reviewsRepositoryProvider).submit(
          briefId: briefId,
          contractorId: contractorId,
          rating: rating,
          comment: comment,
        );
    ref.invalidate(reviewForBriefProvider(briefId));
    ref.invalidate(reviewsForContractorProvider(contractorId));
    // Refresh the contractor's aggregate rating wherever it is shown.
    ref.invalidate(contractorByIdProvider(contractorId));
    ref.invalidate(discoverContractorsProvider);
  }
}
