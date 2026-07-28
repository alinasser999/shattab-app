import 'package:intl/intl.dart';

import 'package:batsh/core/l10n/strings.dart';
import '../domain/quote.dart';

/// Arabic-locale grouping formatter (matches the app's `DateFormat('ar')`),
/// built once instead of per call.
final NumberFormat _egpFormat = NumberFormat.decimalPattern('ar');

/// Human-readable EGP price label for a quote, e.g. "5,000 - 10,000 ج.م".
/// Falls back to "price on inspection" copy when no figures were given.
String quotePriceLabel(Quote q) {
  if (!q.hasPrice) return S.priceOnRequest;
  String n(int v) => _egpFormat.format(v);
  if (q.isFixedPrice) return '${n(q.priceMin!)} ${S.egpUnit}';
  if (q.priceMin != null && q.priceMax != null) {
    return '${n(q.priceMin!)} - ${n(q.priceMax!)} ${S.egpUnit}';
  }
  return '${n(q.priceMin ?? q.priceMax!)} ${S.egpUnit}';
}
