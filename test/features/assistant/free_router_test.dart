import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/features/assistant/data/assistant_repository.dart';
import 'package:batsh/features/assistant/domain/assistant_message.dart';

void main() {
  test('the client payload has no model override', () {
    final payload = AssistantRepository.prepareMessagesPayload([
      AssistantMessage(
        id: 'local-only-id',
        role: AssistantMessageRole.user,
        content: 'محتاج سباك في المعادي',
        timestamp: DateTime.now(),
      ),
    ]);

    expect(payload, hasLength(1));
    expect(payload.single, containsPair('role', 'user'));
    expect(payload.single, containsPair('content', 'محتاج سباك في المعادي'));
    expect(payload.single, isNot(contains('model')));
  });
}
