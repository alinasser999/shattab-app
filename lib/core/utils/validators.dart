/// Lightweight validators shared by form screens.
class Validators {
  const Validators._();

  /// Egyptian E.164 mobile numbers are +20 followed by 10 digits starting with 1.
  static bool isEgyptianPhone(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^\+201[0125]\d{8}$').hasMatch(normalized);
  }

  static bool isNonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  static bool isOtpCode(String value) =>
      RegExp(r'^\d{6}$').hasMatch(value.trim());

  /// Display-name guard — at least 2 characters, no leading/trailing whitespace.
  static bool isReasonableName(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 2 && trimmed.length <= 80;
  }
}
