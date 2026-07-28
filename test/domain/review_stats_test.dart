import 'package:batsh/features/reviews/domain/review.dart';
import 'package:batsh/features/reviews/domain/review_stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// The breakdown is the evidence for the headline average, so it has to survive
/// the cases that would quietly make it lie: an empty list rendering as a
/// rating of zero, a filter silently reshaping the histogram, or a sort that
/// hides the worst reviews from the reader who came looking for them.
Review review({int rating = 5, String? comment, DateTime? createdAt}) => Review(
  id: 'r-${createdAt?.millisecondsSinceEpoch ?? rating}-$comment',
  briefId: 'b1',
  contractorId: 'c1',
  homeownerId: 'h1',
  rating: rating,
  comment: comment,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
);

void main() {
  group('ReviewStats', () {
    test('no reviews means no average, not an average of zero', () {
      final stats = ReviewStats.from(const []);
      expect(stats.average, isNull);
      expect(stats.count, 0);
      expect(stats.shareOf(5), 0);
    });

    test('average and distribution agree with the rows', () {
      final stats = ReviewStats.from([
        review(rating: 5),
        review(rating: 5),
        review(rating: 3),
        review(rating: 1),
      ]);
      expect(stats.count, 4);
      expect(stats.average, 3.5);
      expect(stats.distribution[5], 2);
      expect(stats.distribution[3], 1);
      expect(stats.distribution[1], 1);
      expect(stats.distribution[4], 0);
      expect(stats.shareOf(5), 0.5);
    });

    test('a filter is only offered when it can return something', () {
      final bare = ReviewStats.from([review()]);
      expect(bare.availableFilters, [ReviewFilter.all]);

      final rich = ReviewStats.from([review(comment: 'شغل نضيف'), review()]);
      expect(rich.availableFilters, [
        ReviewFilter.all,
        ReviewFilter.withComment,
      ]);
    });

    test('a whitespace-only comment is not a comment', () {
      expect(ReviewStats.from([review(comment: '   ')]).hasComments, isFalse);
    });
  });

  group('applyReviewView', () {
    final older = review(rating: 2, createdAt: DateTime(2026, 1, 1));
    final newer = review(rating: 5, createdAt: DateTime(2026, 6, 1));
    final newest = review(
      rating: 5,
      comment: 'ممتاز',
      createdAt: DateTime(2026, 7, 1),
    );
    final all = [older, newer, newest];

    test('newest first by default', () {
      final view = applyReviewView(
        all,
        sort: ReviewSort.newest,
        filter: ReviewFilter.all,
      );
      expect(view.map((r) => r.createdAt), [
        newest.createdAt,
        newer.createdAt,
        older.createdAt,
      ]);
    });

    test('the worst reviews are reachable in one tap', () {
      final view = applyReviewView(
        all,
        sort: ReviewSort.lowest,
        filter: ReviewFilter.all,
      );
      expect(view.first.rating, 2);
    });

    test('equal ratings still fall back to recency', () {
      final view = applyReviewView(
        all,
        sort: ReviewSort.highest,
        filter: ReviewFilter.all,
      );
      expect(view.first.createdAt, newest.createdAt);
      expect(view[1].createdAt, newer.createdAt);
    });

    test('filtering narrows the list without dropping the sort', () {
      final view = applyReviewView(
        all,
        sort: ReviewSort.newest,
        filter: ReviewFilter.withComment,
      );
      expect(view.length, 1);
      expect(view.single.comment, 'ممتاز');
    });

    test('the source list is never mutated', () {
      final order = all.map((r) => r.id).toList();
      applyReviewView(all, sort: ReviewSort.lowest, filter: ReviewFilter.all);
      expect(all.map((r) => r.id).toList(), order);
    });
  });
}
