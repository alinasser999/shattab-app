import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/models/draft_photo.dart';
import '../../data/portfolio_repository.dart';
import '../../domain/portfolio_project.dart';
import 'portfolio_providers.dart';

part 'my_portfolio_providers.g.dart';

/// Contractor's own portfolio (driven by the signed-in session id).
@riverpod
Future<List<PortfolioProject>> myPortfolio(Ref ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const [];
  return ref
      .watch(portfolioRepositoryProvider)
      .fetchForContractor(session.user.id);
}

// keepAlive: called one-shot via ref.read(...notifier); autoDispose would
// tear the controller down mid-await and its next ref use would throw.
@Riverpod(keepAlive: true)
class PortfolioController extends _$PortfolioController {
  @override
  void build() {}

  /// Create (when [projectId] is null) or update an existing project.
  /// Already-uploaded photos (url != null) are kept; the rest are uploaded.
  /// The first photo becomes the cover.
  Future<void> save({
    String? projectId,
    required String title,
    String? description,
    String? category,
    String? location,
    int? yearCompleted,
    required List<DraftPhoto> photos,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) throw StateError('No session.');
    final repo = ref.read(portfolioRepositoryProvider);
    final contractorId = session.user.id;
    final draftId =
        projectId ?? DateTime.now().microsecondsSinceEpoch.toString();

    final urls = <String>[];
    final uploadSeqBase = DateTime.now().microsecondsSinceEpoch;
    var uploadCount = 0;
    for (var i = 0; i < photos.length; i++) {
      final p = photos[i];
      if (p.url != null) {
        urls.add(p.url!);
      } else {
        // Use a seq that can't collide with an existing kept photo's path
        // (which may be a small positional index from a prior save) —
        // upsert:true on storage.upload would otherwise silently overwrite
        // the kept photo's file.
        urls.add(await repo.uploadPhoto(
          contractorId: contractorId,
          draftId: draftId,
          seq: uploadSeqBase + uploadCount++,
          file: p.file,
          bytes: p.bytes,
        ));
      }
    }
    final cover = urls.first;

    if (projectId == null) {
      await repo.create(
        contractorId: contractorId,
        title: title,
        description: description,
        coverPhotoUrl: cover,
        photoUrls: urls,
        category: category,
        location: location,
        yearCompleted: yearCompleted,
      );
    } else {
      await repo.update(
        projectId: projectId,
        title: title,
        description: description,
        coverPhotoUrl: cover,
        photoUrls: urls,
        category: category,
        location: location,
        yearCompleted: yearCompleted,
      );
      ref.invalidate(portfolioProjectProvider(projectId));
    }
    ref.invalidate(myPortfolioProvider);
    ref.invalidate(portfolioForContractorProvider(contractorId));
  }

  Future<void> remove(String projectId) async {
    final session = ref.read(currentSessionProvider);
    await ref.read(portfolioRepositoryProvider).delete(projectId);
    ref.invalidate(myPortfolioProvider);
    if (session != null) {
      ref.invalidate(portfolioForContractorProvider(session.user.id));
    }
  }
}