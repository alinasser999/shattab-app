import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/quotes_repository.dart';
import '../../domain/quote.dart';

part 'quotes_providers.g.dart';

/// Homeowner — quotes received on one of their briefs.
@riverpod
Future<List<Quote>> quotesForBrief(Ref ref, String briefId) =>
    ref.watch(quotesRepositoryProvider).fetchForBrief(briefId);

/// Contractor — my quote on a given brief (null until I send one).
@riverpod
Future<Quote?> myQuoteForBrief(Ref ref, String briefId) =>
    ref.watch(quotesRepositoryProvider).fetchMineForBrief(briefId);

/// Contractor — all quotes I have sent (drives inbox status badges).
@riverpod
Future<List<Quote>> myQuotes(Ref ref) =>
    ref.watch(quotesRepositoryProvider).fetchMine();

// keepAlive: called one-shot via ref.read(...notifier); autoDispose would
// tear the controller down mid-await and its next ref use would throw.
@Riverpod(keepAlive: true)
class QuotesController extends _$QuotesController {
  @override
  void build() {}

  Future<void> submit({
    required String briefId,
    int? priceMin,
    int? priceMax,
    String? durationText,
    required String note,
  }) async {
    await ref.read(quotesRepositoryProvider).submit(
          briefId: briefId,
          priceMin: priceMin,
          priceMax: priceMax,
          durationText: durationText,
          note: note,
        );
    ref.invalidate(myQuoteForBriefProvider(briefId));
    ref.invalidate(quotesForBriefProvider(briefId));
    ref.invalidate(myQuotesProvider);
  }

  Future<void> setStatus({
    required String quoteId,
    required String briefId,
    required QuoteStatus status,
  }) async {
    await ref.read(quotesRepositoryProvider).setStatus(quoteId, status);
    ref.invalidate(quotesForBriefProvider(briefId));
    ref.invalidate(myQuoteForBriefProvider(briefId));
    ref.invalidate(myQuotesProvider);
  }
}
