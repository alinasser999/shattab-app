import 'package:batsh/core/l10n/strings.dart';
import 'package:batsh/core/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  group('formatRelativeTime', () {
    test('returns minutes string for times under an hour', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 5));
      final result = formatRelativeTime(dt);
      expect(result, equals(S.minsAgo(5)));
    });

    test('returns singular minute for 1 minute ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 1));
      final result = formatRelativeTime(dt);
      expect(result, equals(S.minAgo(1)));
    });

    test('returns hours string for times between 1 and 24 hours', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      final result = formatRelativeTime(dt);
      expect(result, equals(S.hoursAgo(3)));
    });

    test('returns singular hour for 1 hour ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 1));
      final result = formatRelativeTime(dt);
      expect(result, equals(S.hourAgo(1)));
    });

    test('returns days string for times between 1 and 7 days', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      final result = formatRelativeTime(dt);
      expect(result, equals(S.daysAgo(3)));
    });

    test('returns singular day for 1 day ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      final result = formatRelativeTime(dt);
      expect(result, equals(S.dayAgo(1)));
    });

    test('returns formatted date for times 7+ days ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 30));
      final result = formatRelativeTime(dt);
      expect(result, isNot(contains('قبل')));
      expect(result, isNotEmpty);
    });
  });
}
