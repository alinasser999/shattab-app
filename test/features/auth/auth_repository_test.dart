import 'dart:convert';

import 'package:batsh/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('signup confirmation resend posts a phone SMS resend request', () async {
    http.Request? captured;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{}', 200, request: request);
      }),
    );
    final repository = AuthRepository(client);

    await repository.resendPhoneSignupConfirmation('opaque-test-phone');

    expect(captured?.url.path, '/auth/v1/resend');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['type'], 'sms');
    expect(body['phone'], 'opaque-test-phone');
    expect(body, isNot(contains('email')));
  });
}
