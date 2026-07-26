import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/review.dart';

part 'reviews_repository.g.dart';

class ReviewsRepository {
  ReviewsRepository(this._client);
  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  /// The review on a given brief, or null if none yet (RLS: public read).
  Future<Review?> fetchForBrief(String briefId) async {
    final row = await _client
        .from('reviews')
        .select()
        .eq('brief_id', briefId)
        .maybeSingle();
    return row == null ? null : Review.fromJson(row);
  }

  /// Cap on the reviews list.
  ///
  /// The sheet shows a scrollable list, and the headline average and count on
  /// the profile come from the `review_count` / `review_avg` rollup (0012), not
  /// from counting these rows. A contractor with 800 reviews should not
  /// transfer all of them to render the first screenful.
  static const int maxRows = 100;

  /// The most recent reviews a contractor has received, newest first.
  Future<List<Review>> fetchForContractor(String contractorId) async {
    final rows = await _client
        .from('reviews')
        .select()
        .eq('contractor_id', contractorId)
        .order('created_at', ascending: false)
        .limit(maxRows);
    return rows.map(Review.fromJson).toList();
  }

  /// Create or update the review for a brief. Insert is gated by RLS to an
  /// accepted quote from this contractor on this brief.
  Future<Review> submit({
    required String briefId,
    required String contractorId,
    required int rating,
    String? comment,
  }) async {
    final row = await _client
        .from('reviews')
        .upsert(
          {
            'brief_id': briefId,
            'contractor_id': contractorId,
            'homeowner_id': _uid,
            'rating': rating,
            'comment': comment,
          },
          onConflict: 'brief_id',
        )
        .select()
        .single();
    return Review.fromJson(row);
  }
}

@Riverpod(keepAlive: true)
ReviewsRepository reviewsRepository(Ref ref) =>
    ReviewsRepository(ref.watch(supabaseClientProvider));
