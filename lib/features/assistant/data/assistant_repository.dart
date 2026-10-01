// Supabase transport for the Arabic-first assistant.
//
// The client sends only bounded, redacted messages. The Edge Function owns the
// OpenRouter key and pins the runtime model to openrouter/free.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/assistant_envelope.dart';
import '../domain/assistant_message.dart';

class AssistantRepository {
  AssistantRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  static final _phonePattern = RegExp(r'(?:\+?20|0)?1[0125]\d{8}');
  static final _emailPattern = RegExp(
    r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+',
  );
  static final _cardPattern = RegExp(
    r'\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b',
  );
  static final _nationalIdPattern = RegExp(r'\b\d{14}\b');
  static final _uuidPattern = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
  );
  static final _urlPattern = RegExp(r'https?://[^\s]+');

  static String redactPii(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll(_phonePattern, '[رقم محذوف]')
        .replaceAll(_emailPattern, '[بريد محذوف]')
        .replaceAll(_uuidPattern, '[معرف محذوف]')
        .replaceAll(_cardPattern, '[بطاقة محذوفة]')
        .replaceAll(_nationalIdPattern, '[رقم قومي محذوف]')
        .replaceAll(_urlPattern, '[رابط محذوف]');
  }

  /// Caps history before transport. Message IDs and timestamps never leave
  /// the client because the Edge Function does not need them.
  static List<Map<String, String>> prepareMessagesPayload(
    List<AssistantMessage> messages,
  ) {
    final recent = messages.length > 6
        ? messages.sublist(messages.length - 6)
        : messages;
    final payload = <Map<String, String>>[];
    for (final message in recent) {
      final content = redactPii(message.content.trim());
      final bounded = content.length > 500
          ? content.substring(0, 500)
          : content;
      if (bounded.isNotEmpty) {
        payload.add({
          'role': message.isAssistant ? 'assistant' : 'user',
          'content': bounded,
        });
      }
    }
    return payload;
  }

  Future<AssistantEnvelope> sendMessage({
    required List<AssistantMessage> history,
    String audience = 'homeowner',
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) return AssistantEnvelope.safeFallback;

    final messages = prepareMessagesPayload(history);
    if (messages.isEmpty) return AssistantEnvelope.safeFallback;

    try {
      final response = await _supabase.functions
          .invoke(
            'assistant-chat',
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
            body: {
              // Deliberately no model field. The Edge Function pins the only
              // permitted runtime model to openrouter/free.
              'audience': audience == 'contractor' ? 'contractor' : 'homeowner',
              'messages': messages,
            },
          )
          .timeout(const Duration(seconds: 18));

      final data = response.data;
      if (data is Map<String, dynamic>) return AssistantEnvelope.fromJson(data);
      if (data is Map) {
        return AssistantEnvelope.fromJson(Map<String, dynamic>.from(data));
      }
      return AssistantEnvelope.safeFallback;
    } catch (_) {
      return AssistantEnvelope.safeFallback;
    }
  }
}
