import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../../data/professional_contact_repository.dart';
import '../../domain/professional_contact_episode.dart';

final professionalContactEpisodeProvider =
    FutureProvider.autoDispose<ProfessionalContactEpisode?>((ref) async {
      final session = ref.watch(currentSessionProvider);
      if (session == null) return null;

      final profile = await ref.watch(currentProfileProvider.future);
      if (profile?.id != session.user.id ||
          profile?.role != UserRole.homeowner) {
        return null;
      }

      return ref
          .watch(professionalContactRepositoryProvider)
          .fetchOldestDueReview();
    });

final professionalContactActionsProvider = Provider<ProfessionalContactActions>(
  ProfessionalContactActions.new,
);

class ProfessionalContactActions {
  const ProfessionalContactActions(this._ref);

  final Ref _ref;

  /// Capturing the launch is best-effort and never delays the external handoff.
  Future<void> recordSuccessfulWhatsApp(String contractorId) async {
    try {
      await _ref
          .read(professionalContactRepositoryProvider)
          .recordWhatsAppContact(contractorId);
    } catch (_) {
      // Contact still opened successfully; capture failure stays unobtrusive.
    }
  }

  Future<void> dismiss(String episodeId) async {
    await _ref.read(professionalContactRepositoryProvider).dismiss(episodeId);
    _ref.invalidate(professionalContactEpisodeProvider);
  }

  Future<void> markNotWorkedTogether(String episodeId) async {
    await _ref
        .read(professionalContactRepositoryProvider)
        .markNotWorkedTogether(episodeId);
    _ref.invalidate(professionalContactEpisodeProvider);
  }

  Future<void> submitReview({
    required String episodeId,
    required String contractorId,
    required int rating,
    required String? comment,
  }) async {
    final review = await _ref
        .read(professionalContactRepositoryProvider)
        .submitReview(episodeId: episodeId, rating: rating, comment: comment);
    if (review == null) throw StateError('Contact review is no longer due.');

    _ref.invalidate(professionalContactEpisodeProvider);
    _ref.invalidate(reviewsForContractorProvider(contractorId));
    _ref.invalidate(contractorByIdProvider(contractorId));
    _ref.invalidate(discoverContractorsProvider);
  }
}
