import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the one duplication in the push pipeline.
///
/// `supabase/functions/send-push/index.ts` has to carry its own copy of the
/// notification strings: it renders them on a server, for an app that is not
/// running, so it cannot reach the Flutter catalogue. That duplication is
/// deliberate — but a duplicate nobody checks is just a future bug where the
/// in-app text says one thing and the lock screen says another, or where a
/// reworded string silently keeps its old wording in push forever.
///
/// This test is what makes the trade survivable: change a string in the ARB and
/// forget the Edge Function, and the suite fails here naming the key.
void main() {
  late String source;
  late Map<String, dynamic> ar;
  late Map<String, dynamic> en;
  late List<String> keys;

  setUpAll(() {
    source = File('supabase/functions/send-push/index.ts').readAsStringSync();
    ar =
        jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync())
            as Map<String, dynamic>;
    en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;

    // Top-level entries of the COPY object: two-space indent, then the key.
    keys = RegExp(
      r'^  (notification[A-Za-z]+): \{',
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toList();
  });

  test('the Edge Function declares copy for the keys it can be sent', () {
    // A sanity floor. Without it, a change to the file's shape would break the
    // regex and every assertion below would pass vacuously over an empty list.
    expect(keys.length, greaterThan(15));
    expect(keys, contains('notificationNewQuoteTitle'));
    expect(keys, contains('notificationNewQuoteBody'));
  });

  test('every key in the Edge Function exists in both ARB files', () {
    for (final key in keys) {
      expect(
        ar.containsKey(key),
        isTrue,
        reason: '$key missing from app_ar.arb',
      );
      expect(
        en.containsKey(key),
        isTrue,
        reason: '$key missing from app_en.arb',
      );
    }
  });

  test('the Edge Function text matches the ARB word for word', () {
    for (final key in keys) {
      expect(
        source,
        contains("'${ar[key]}'"),
        reason:
            'Arabic copy for $key drifted. app_ar.arb says "${ar[key]}" — '
            'update supabase/functions/send-push/index.ts to match.',
      );
      expect(
        source,
        contains("'${en[key]}'"),
        reason:
            'English copy for $key drifted. app_en.arb says "${en[key]}" — '
            'update supabase/functions/send-push/index.ts to match.',
      );
    }
  });

  test('every notification kind the triggers can write has body copy', () {
    // Kinds come from the CHECK constraint in
    // 20260803202740_notifications_and_analytics_contract.sql. A migration that
    // adds a kind without adding copy would ship a push whose body falls back
    // to the generic title and tells the user nothing.
    const bodyKeyByKind = {
      'new_quote': 'notificationNewQuoteBody',
      'quote_accepted': 'notificationQuoteAcceptedBody',
      'quote_declined': 'notificationQuoteDeclinedBody',
      'completion_requested': 'notificationCompletionRequestedBody',
      'job_completed': 'notificationJobCompletedBody',
      'new_review': 'notificationNewReviewBody',
      'verification_approved': 'notificationVerificationApprovedBody',
      'verification_rejected': 'notificationVerificationRejectedBody',
      'payment_approved': 'notificationPaymentApprovedBody',
      'payment_rejected': 'notificationPaymentRejectedBody',
    };

    for (final entry in bodyKeyByKind.entries) {
      expect(
        keys,
        contains(entry.value),
        reason: 'Notification kind "${entry.key}" would send with no body.',
      );
    }
  });
}
