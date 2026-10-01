import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/features/assistant/data/assistant_repository.dart';
import 'package:batsh/features/assistant/domain/assistant_message.dart';

void main() {
  group('assistant redaction and capping', () {
    test('redacts contact and identity data', () {
      const input =
          'اتصل بيا على 01012345678 أو user@example.com ومعرف daa00000-0000-0000-0000-000000000001';
      final redacted = AssistantRepository.redactPii(input);

      expect(redacted, isNot(contains('01012345678')));
      expect(redacted, isNot(contains('user@example.com')));
      expect(redacted, isNot(contains('daa00000')));
      expect(redacted, contains('[رقم محذوف]'));
      expect(redacted, contains('[بريد محذوف]'));
      expect(redacted, contains('[معرف محذوف]'));
    });

    test('keeps only the latest six messages and caps each message', () {
      final messages = List.generate(
        10,
        (index) => AssistantMessage(
          id: '$index',
          role: index.isEven
              ? AssistantMessageRole.user
              : AssistantMessageRole.assistant,
          content: index == 9 ? 'أ' * 700 : 'رسالة $index',
          timestamp: DateTime.now(),
        ),
      );

      final payload = AssistantRepository.prepareMessagesPayload(messages);

      expect(payload, hasLength(6));
      expect(payload.first['content'], 'رسالة 4');
      expect(payload.last['content'], hasLength(500));
    });
  });
}
