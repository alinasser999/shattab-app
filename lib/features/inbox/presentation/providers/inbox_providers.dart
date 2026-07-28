import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../briefs/presentation/providers/briefs_providers.dart';
import '../../../quotes/domain/quote.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../domain/received_request.dart';

part 'inbox_providers.g.dart';

/// Direct briefs targeted at the current contractor, left-joined with the
/// contractor's own quotes to surface a per-request status badge.
@riverpod
Future<List<ReceivedRequest>> inboxRequests(Ref ref) async {
  final briefs = await ref.watch(contractorDirectBriefsProvider.future);
  final quotes = await ref.watch(myQuotesProvider.future);
  final byBrief = <String, QuoteStatus>{
    for (final q in quotes) q.briefId: q.status,
  };
  return [
    for (final b in briefs)
      ReceivedRequest(brief: b, quoteStatus: byBrief[b.id]),
  ];
}
