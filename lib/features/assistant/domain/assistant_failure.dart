/// A sanitized failure category exposed by the assistant transport boundary.
///
/// It intentionally carries no provider response, exception text, or request
/// content so presentation code can select localized recovery copy safely.
enum AssistantFailureType {
  quotaExceeded,
  authenticationRequired,
  temporaryService,
}

class AssistantFailure implements Exception {
  const AssistantFailure(this.type);

  final AssistantFailureType type;
}
