import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../briefs/domain/brief.dart';
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

/// Contractor — free-quote allowance for this month.
///
/// Drives the send-quote CTA: Pro sends without limit, a free contractor sends
/// until the quota is spent and only then sees the paywall.
@riverpod
Future<({bool isPro, int used, int quota})> myQuoteQuota(Ref ref) =>
    ref.watch(quotesRepositoryProvider).fetchQuota();

/// Contractor — my quotes with each brief already joined on.
///
/// Backs the quotes screen, which needs the brief for the row title and the
/// completion card. Fetching them together is one request; resolving the brief
/// per row was one request per quote.
@riverpod
Future<List<({Quote quote, Brief? brief})>> myQuotesWithBriefs(Ref ref) =>
    ref.watch(quotesRepositoryProvider).fetchMineWithBriefs();

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
    await ref
        .read(quotesRepositoryProvider)
        .submit(
          briefId: briefId,
          priceMin: priceMin,
          priceMax: priceMax,
          durationText: durationText,
          note: note,
        );
    ref.invalidate(myQuoteForBriefProvider(briefId));
    ref.invalidate(quotesForBriefProvider(briefId));
    ref.invalidate(myQuotesProvider);
    ref.invalidate(myQuotesWithBriefsProvider);
    // Sending or withdrawing a quote moves the free-quota counter.
    ref.invalidate(myQuoteQuotaProvider);
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
    ref.invalidate(myQuotesWithBriefsProvider);
    // Sending or withdrawing a quote moves the free-quota counter.
    ref.invalidate(myQuoteQuotaProvider);
  }
}
