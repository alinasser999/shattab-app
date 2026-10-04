import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../reviews/domain/review.dart';
import '../domain/professional_contact_episode.dart';

class ProfessionalContactRepository {
  ProfessionalContactRepository(this._client);

  final SupabaseClient _client;

  Future<void> recordWhatsAppContact(String contractorId) async {
    await _client.rpc(
      'record_professional_whatsapp_contact',
      params: {'p_contractor_id': contractorId},
    );
  }

  Future<ProfessionalContactEpisode?> fetchOldestDueReview() async {
    final result = await _client.rpc(
      'get_oldest_due_professional_contact_review',
    );
    final rows = result as List<dynamic>;
    if (rows.isEmpty) return null;
    return ProfessionalContactEpisode.fromJson(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }

  Future<void> dismiss(String episodeId) async {
    await _client.rpc(
      'dismiss_professional_contact_review',
      params: {'p_episode_id': episodeId},
    );
  }

  Future<void> markNotWorkedTogether(String episodeId) async {
    await _client.rpc(
      'mark_not_worked_together',
      params: {'p_episode_id': episodeId},
    );
  }

  Future<Review?> submitReview({
    required String episodeId,
    required int rating,
    required String? comment,
  }) async {
    final result = await _client.rpc(
      'submit_professional_contact_review',
      params: {
        'p_episode_id': episodeId,
        'p_rating': rating,
        'p_comment': comment,
      },
    );
    if (result == null) return null;

    final row = await _client
        .from('reviews')
        .select()
        .eq('id', result.toString())
        .maybeSingle();
    return row == null ? null : Review.fromJson(row);
  }
}

final professionalContactRepositoryProvider =
    Provider<ProfessionalContactRepository>(
      (ref) => ProfessionalContactRepository(ref.watch(supabaseClientProvider)),
    );
