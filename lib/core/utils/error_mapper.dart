import '../l10n/strings.dart';

/// Maps exceptions to safe user-facing Arabic error messages.
/// Never exposes internal error details to users.
class ErrorMapper {
  const ErrorMapper._();

  /// Returns a user-friendly message for any exception.
  /// Prevents sensitive info (stack traces, DB details) from leaking to users.
  static String map(dynamic error) {
    final msg = error.toString().toLowerCase();

    // Auth errors
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
    if (msg.contains('upload') || msg.contains('storage')) {
      return S.errPhotoUpload;
    }

    // Default
    return S.errServerError;
  }
}
