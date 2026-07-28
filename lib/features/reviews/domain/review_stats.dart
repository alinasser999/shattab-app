import 'package:batsh/features/reviews/domain/review.dart';

/// Reviews carry a rating and an optional comment, and nothing else.
///
/// A `withPhotos` value used to sit here. `reviews` has no photo column in any
/// migration — `photo_urls` belongs to `briefs` (0004) — so the filter offered
/// a view that could never return a row.
enum ReviewFilter { all, withComment }

enum ReviewSort { newest, lowest, highest }

class ReviewStats {
  final double? average;
  final int count;
  final Map<int, int> distribution;
  final List<ReviewFilter> availableFilters;
  final bool hasComments;

  ReviewStats._({
    this.average,
    required this.count,
    required this.distribution,
    required this.availableFilters,
    required this.hasComments,
  });

  factory ReviewStats.from(List<Review> reviews) {
    if (reviews.isEmpty) {
      return ReviewStats._(
        average: null,
        count: 0,
        distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        availableFilters: [ReviewFilter.all],
        hasComments: false,
      );
    }

    int sum = 0;
    Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    bool hasComments = false;

    for (final review in reviews) {
      sum += review.rating;
      dist[review.rating] = (dist[review.rating] ?? 0) + 1;
      if (review.comment != null && review.comment!.trim().isNotEmpty) {
        hasComments = true;
      }
    }

    // A filter is offered only when it would actually narrow the list.
    List<ReviewFilter> filters = [ReviewFilter.all];
    if (hasComments) filters.add(ReviewFilter.withComment);

    return ReviewStats._(
      average: sum / reviews.length,
      count: reviews.length,
      distribution: dist,
      availableFilters: filters,
      hasComments: hasComments,
    );
  }

  double shareOf(int rating) {
    if (count == 0) return 0;
    return (distribution[rating] ?? 0) / count;
  }
}

List<Review> applyReviewView(
  List<Review> reviews, {
  required ReviewSort sort,
  required ReviewFilter filter,
}) {
  List<Review> result = List.from(reviews);

  if (filter == ReviewFilter.withComment) {
    result.retainWhere(
      (r) => r.comment != null && r.comment!.trim().isNotEmpty,
    );
  }

  result.sort((a, b) {
    if (sort == ReviewSort.lowest) {
      int c = a.rating.compareTo(b.rating);
      if (c != 0) return c;
    } else if (sort == ReviewSort.highest) {
      int c = b.rating.compareTo(a.rating);
      if (c != 0) return c;
    }
    return b.createdAt.compareTo(a.createdAt);
  });

  return result;
}
