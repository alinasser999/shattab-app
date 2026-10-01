import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/features/assistant/domain/assistant_envelope.dart';
import 'package:batsh/features/assistant/domain/specialty_catalog.dart';

void main() {
  group('AssistantEnvelope', () {
    test('accepts a bounded discovery envelope', () {
      final envelope = AssistantEnvelope.fromJson({
        'intent': 'discovery',
        'reply': 'وجدت لك محترفين في الجيزة.',
        'next_question': 'هل تحتاج تأسيساً أم صيانة؟',
        'specialty_key': 'سباك',
        'city_key': 'الجيزة',
        'help_action_id': 'browse_contractors',
        'quick_replies': ['تأسيس كامل', 'صيانة سريعة'],
        'contractor_id': 'must-never-cross-the-boundary',
      });

      expect(envelope.intent, 'discovery');
      expect(envelope.specialtyKey, 'plumbing');
      expect(envelope.cityKey, 'الجيزة');
      expect(envelope.helpActionId, 'browse_contractors');
      expect(envelope.quickReplies, ['تأسيس كامل', 'صيانة سريعة']);
    });

    test('uses the complete shared specialty taxonomy', () {
      expect(
        SpecialtyCatalog.canonicalSpecialties,
        containsAll([
          'plumbing',
          'paint',
          'plastering',
          'gypsum_board',
          'marble_granite',
          'aluminum_upvc',
          'hvac',
        ]),
      );
      expect(SpecialtyCatalog.canonicalSpecialties, isNot(contains('random')));
    });

    test('rejects unknown keys and redacts unsafe reply content', () {
      final envelope = AssistantEnvelope.fromJson({
        'intent': 'not-an-intent',
        'reply':
            'اتصل على 01012345678 أو افتح https://example.invalid بمعرف 123e4567-e89b-12d3-a456-426614174000 وسعر 500 جنيه',
        'specialty_key': 'rocket_science',
        'city_key': 'New York',
        'help_action_id': '/arbitrary-route',
      });

      expect(envelope.intent, 'general');
      expect(envelope.specialtyKey, isNull);
      expect(envelope.cityKey, isNull);
      expect(envelope.helpActionId, isNull);
      expect(envelope.reply, isNot(contains('01012345678')));
      expect(envelope.reply, isNot(contains('https://')));
      expect(envelope.reply, isNot(contains('123e4567')));
      expect(envelope.reply, contains('[رقم محذوف]'));
      expect(envelope.reply, contains('[رابط محذوف]'));
      expect(envelope.reply, contains('[معرف محذوف]'));
      expect(envelope.reply, isNot(contains('500 جنيه')));
    });

    test('falls back deterministically when quick replies are invalid', () {
      final envelope = AssistantEnvelope.fromJson({
        'reply': 'رد قصير',
        'quick_replies': [null, '', 42],
      });

      expect(envelope.reply, 'رد قصير');
      expect(
        envelope.quickReplies,
        AssistantEnvelope.safeFallback.quickReplies,
      );
    });

    test('keeps help actions inside the current portal', () {
      expect(
        SpecialtyCatalog.resolveHelpActionRoute('browse_contractors'),
        '/h/discover',
      );
      expect(
        SpecialtyCatalog.resolveHelpActionRoute(
          'view_portfolio',
          isHomeowner: false,
        ),
        '/c/portfolio',
      );
      expect(
        SpecialtyCatalog.resolveHelpActionRoute(
          'post_brief',
          isHomeowner: false,
        ),
        isNull,
      );
    });
  });
}
