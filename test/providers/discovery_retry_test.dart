import 'package:flutter_test/flutter_test.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';

void main() {
  test('discovery retries twice before surfacing an error', () {
    final error = Exception('network unavailable');

    expect(discoveryRetry(0, error), const Duration(milliseconds: 300));
    expect(discoveryRetry(1, error), const Duration(milliseconds: 600));
    expect(discoveryRetry(2, error), isNull);
  });
}
