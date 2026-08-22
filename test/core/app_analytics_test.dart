import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/core/analytics/app_analytics.dart';

void main() {
  test('analytics properties remove identifying and free-text values', () {
    final properties = AppAnalytics.sanitizeProperties({
      'source_screen': 'home',
      'request_id': 'brief-123',
      'request_city': 'Cairo',
      'has_price': true,
      'rating': 5,
      'note': 'A private message',
      'device_token': 'secret',
    });

    expect(properties, {
      'source_screen': 'home',
      'has_price': true,
      'rating': 5,
    });
  });

  test('analytics properties keep bounded scalar values only', () {
    final properties = AppAnalytics.sanitizeProperties({
      'role': 'contractor',
      'count': 3,
      'enabled': false,
      'long_value': 'x' * 81,
      'nested': {'not': 'allowed'},
      'line_break': 'first\nsecond',
      'latitude': 30.1,
    });

    expect(properties, {'role': 'contractor', 'count': 3, 'enabled': false});
  });
}
