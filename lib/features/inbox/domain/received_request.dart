import '../../briefs/domain/brief.dart';
import '../../quotes/domain/quote.dart';

/// A direct brief sent to the current contractor, paired with the status of
/// the contractor's own quote on it (null when none has been sent yet).
class ReceivedRequest {
  const ReceivedRequest({required this.brief, this.quoteStatus});

  final Brief brief;
  final QuoteStatus? quoteStatus;
}