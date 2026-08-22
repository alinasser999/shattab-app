import '../l10n/strings.dart';

/// Maps exceptions to safe user-facing Arabic error messages.
/// Never exposes internal error details to users.
class ErrorMapper {
  const ErrorMapper._();

  /// Returns a user-friendly message for any exception.
  /// Prevents sensitive info (stack traces, DB details) from leaking to users.
  static String map(dynamic error) {
    final msg = error.toString().toLowerCase();

    // Framework lifecycle errors (e.g. Riverpod "Cannot use the Ref ... after
    // it has been disposed", whose hint text contains the word "invalidate").
    // These are bugs, not user-data problems — never map them to errInvalidData.
    if (msg.contains('disposed') || msg.contains('ref.mounted')) {
      return S.errServerError;
    }

    // Auth errors
    if (msg.contains('signups') && msg.contains('disabled')) {
      return S.errSignupDisabled;
    }
    if (msg.contains('phone_provider_disabled') ||
        msg.contains('phone provider') && msg.contains('disabled')) {
      return S.errSignupDisabled;
    }
    if (msg.contains('weak password') ||
        msg.contains('password should') ||
        msg.contains('password must')) {
      return S.errInvalidData;
    }
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user already exists')) {
      return S.errPhoneTaken;
    }
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('email not confirmed')) {
      return S.errAuthFailed;
    }
    if (msg.contains('otp') && msg.contains('expired')) {
      return S.errOtpExpired;
    }
    if (msg.contains('otp') || msg.contains('sms') || msg.contains('token')) {
      return S.errOtpFailed;
    }
    if (msg.contains('session') && msg.contains('not found')) {
      return S.errSessionExpired;
    }

    // Network / timeout errors
    if (msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('socket') ||
        msg.contains('dns')) {
      return S.errNetwork;
    }

    // Bare error codes raised by our own RPCs (accept_quote in 0009,
    // request_completion / confirm_completion in 0019). These must be matched
    // before the generic checks below: the underscored forms never match the
    // spaced ones, so `brief_not_found` was falling through to a generic
    // server error instead of "not found", and `not_authorized` does not
    // contain the substring "unauthorized".
    if (msg.contains('not_hired')) {
      return S.errNotHiredYet;
    }
    if (msg.contains('brief_not_found') || msg.contains('quote_not_found')) {
      return S.errNotFound;
    }
    if (msg.contains('not_authorized')) {
      return S.errPermissionDenied;
    }

    // Permission errors
    if (msg.contains('permission') ||
        msg.contains('unauthorized') ||
        msg.contains('policy') ||
        msg.contains('row level security')) {
      return S.errPermissionDenied;
    }

    // Not found
    if (msg.contains('not found') || msg.contains('does not exist')) {
      return S.errNotFound;
    }

    // Data / parse errors
    if (msg.contains('invalid') ||
        msg.contains('constraint') ||
        msg.contains('format') ||
        msg.contains('parse') ||
        msg.contains('type')) {
      return S.errInvalidData;
    }

    // Storage / upload
    if (msg.contains('image_too_large') || msg.contains('empty_image')) {
      return S.errPhotoUpload;
    }
    if (msg.contains('upload') || msg.contains('storage')) {
      return S.errPhotoUpload;
    }

    // Default
    return S.errServerError;
  }
}
