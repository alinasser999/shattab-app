// Validated, bounded data returned by the assistant boundary.
//
// This type deliberately contains no contractor IDs, contact details, prices,
// ratings, verification claims, or arbitrary routes. Discovery remains the
// source of truth for real professionals.

import 'package:batsh/features/assistant/domain/specialty_catalog.dart';

class AssistantEnvelope {
  const AssistantEnvelope({
    required this.intent,
    required this.reply,
    this.nextQuestion,
    this.specialtyKey,
    this.cityKey,
    this.helpActionId,
    this.quickReplies = const [],
  });

  final String intent;
  final String reply;
  final String? nextQuestion;
  final String? specialtyKey;
  final String? cityKey;
  final String? helpActionId;
  final List<String> quickReplies;

  static const AssistantEnvelope safeFallback = AssistantEnvelope(
    intent: 'fallback',
    reply:
        'أهلاً بك في شطّب. أقدر أساعدك في العثور على محترفين مناسبين لتشطيب بيتك أو فهم خطوات التنفيذ.',
    nextQuestion: 'ما هي الخدمة أو المحافظة التي تبحث عنها؟',
    helpActionId: 'browse_contractors',
    quickReplies: ['تصفح المحترفين', 'نشر طلب جديد', 'سباكة', 'دهانات'],
  );

  static const _validIntents = {
    'discovery',
    'consultation',
    'clarification',
    'help_action',
    'general',
    'fallback',
  };

  static final _phonePattern = RegExp(r'(?:\+?20|0)?1[0125]\d{8}');
  static final _emailPattern = RegExp(
    r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+',
  );
  static final _uuidPattern = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
  );
  static final _urlPattern = RegExp(r'https?://[^\s]+');
  static final _pricePattern = RegExp(
    r'[\d٠-٩][\d٠-٩,\.\s]*\s*(?:جنيه|ج\.م|EGP)',
    caseSensitive: false,
  );
  static final _ratingPattern = RegExp(
    r'(?:تقييم|نجوم)\s*[\d٠-٩](?:[.,][\d٠-٩])?',
    caseSensitive: false,
  );

  factory AssistantEnvelope.fromJson(Map<String, dynamic> json) {
    final rawIntent = json['intent'];
    final intent =
        rawIntent is String && _validIntents.contains(rawIntent.trim())
        ? rawIntent.trim()
        : 'general';

    final rawReply = json['reply'];
    final reply = rawReply is String && rawReply.trim().isNotEmpty
        ? _boundText(_sanitizeText(rawReply), 1200)
        : safeFallback.reply;

    final rawNextQuestion = json['next_question'] ?? json['nextQuestion'];
    final nextQuestion =
        rawNextQuestion is String && rawNextQuestion.trim().isNotEmpty
        ? _boundText(_sanitizeText(rawNextQuestion), 280)
        : null;

    final rawSpecialty =
        json['specialty_key'] ?? json['specialtyKey'] ?? json['specialty'];
    final rawCity = json['city_key'] ?? json['cityKey'] ?? json['city'];
    final rawHelpAction = json['help_action_id'] ?? json['helpActionId'];

    final quickReplies = <String>[];
    final rawQuickReplies = json['quick_replies'] ?? json['quickReplies'];
    if (rawQuickReplies is List) {
      for (final item in rawQuickReplies) {
        if (item is String && item.trim().isNotEmpty) {
          final value = _boundText(_sanitizeText(item), 40);
          if (value.isNotEmpty) quickReplies.add(value);
        }
        if (quickReplies.length == 4) break;
      }
    }

    return AssistantEnvelope(
      intent: intent,
      reply: reply.isEmpty ? safeFallback.reply : reply,
      nextQuestion: nextQuestion?.isEmpty == true ? null : nextQuestion,
      specialtyKey: SpecialtyCatalog.canonicalizeSpecialty(
        rawSpecialty is String ? rawSpecialty : null,
      ),
      cityKey: SpecialtyCatalog.canonicalizeCity(
        rawCity is String ? rawCity : null,
      ),
      helpActionId: SpecialtyCatalog.canonicalizeHelpAction(
        rawHelpAction is String ? rawHelpAction : null,
      ),
      quickReplies: quickReplies.isEmpty
          ? safeFallback.quickReplies
          : quickReplies,
    );
  }

  Map<String, dynamic> toJson() => {
    'intent': intent,
    'reply': reply,
    if (nextQuestion != null) 'next_question': nextQuestion,
    if (specialtyKey != null) 'specialty_key': specialtyKey,
    if (cityKey != null) 'city_key': cityKey,
    if (helpActionId != null) 'help_action_id': helpActionId,
    'quick_replies': quickReplies,
  };

  static String _sanitizeText(String text) {
    var clean = text
        .replaceAll(_phonePattern, '[رقم محذوف]')
        .replaceAll(_emailPattern, '[بريد محذوف]')
        .replaceAll(_uuidPattern, '[معرف محذوف]')
        .replaceAll(_urlPattern, '[رابط محذوف]')
        .replaceAll(_pricePattern, 'التكلفة تحدد حسب المعاينة')
        .replaceAll(_ratingPattern, '');
    return clean.trim();
  }

  static String _boundText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 1).trim()}…';
  }
}
