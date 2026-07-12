import 'package:intl/intl.dart';

import '../l10n/strings.dart';

String formatRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? S.minAgo(m) : S.minsAgo(m);
  } else if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? S.hourAgo(h) : S.hoursAgo(h);
  } else if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? S.dayAgo(d) : S.daysAgo(d);
  }
  return DateFormat.yMMMd('ar').format(dt);
}
