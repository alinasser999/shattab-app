import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/core/logging/app_logger.dart';

void main() {
  test('redacts credentials and personal fields from diagnostic values', () {
    final result = AppLogger.sanitizeForLog(
      'password=secret token:abc email=user@example.com phone=01012345678',
    );

    expect(result, isNot(contains('secret')));
    expect(result, isNot(contains('abc')));
    expect(result, isNot(contains('user@example.com')));
    expect(result, isNot(contains('01012345678')));
    expect(RegExp(r'\[REDACTED\]').allMatches(result).length, 4);
  });

  test('caps unusually large diagnostic values', () {
    final result = AppLogger.sanitizeForLog('x' * 600);

    expect(result.length, 503);
    expect(result.endsWith('...'), isTrue);
  });
}
