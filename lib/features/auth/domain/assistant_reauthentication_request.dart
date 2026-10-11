import '../../../core/router/routes.dart';
import 'profile.dart';

/// Ephemeral intent for recovering one assistant turn through the original
/// account. The challenge never carries transcript text or credentials.
class AssistantReauthenticationRequest {
  const AssistantReauthenticationRequest({
    required this.originalUserId,
    required this.expectedRole,
    required this.assistantRoute,
    required this.failedTurnId,
  });

  final String originalUserId;
  final UserRole expectedRole;
  final String assistantRoute;
  final String failedTurnId;

  bool get isValid =>
      originalUserId.isNotEmpty &&
      failedTurnId.isNotEmpty &&
      assistantRoute == routeForRole(expectedRole);

  static String routeForRole(UserRole role) => switch (role) {
    UserRole.homeowner => Routes.homeownerAssistant,
    UserRole.contractor => Routes.contractorAssistant,
  };
}

/// Result returned only after the active session and refreshed profile match
/// the account and locked role captured by the challenge.
class AssistantReauthenticationOutcome {
  const AssistantReauthenticationOutcome({
    required this.originalUserId,
    required this.expectedRole,
    required this.assistantRoute,
    required this.failedTurnId,
  });

  final String originalUserId;
  final UserRole expectedRole;
  final String assistantRoute;
  final String failedTurnId;

  bool matches(AssistantReauthenticationRequest request) =>
      originalUserId == request.originalUserId &&
      expectedRole == request.expectedRole &&
      assistantRoute == request.assistantRoute &&
      failedTurnId == request.failedTurnId &&
      request.isValid;
}

/// A single, short-lived in-memory route challenge. Identity comparison makes
/// a manually constructed or deep-linked request insufficient to open the
/// reauthentication page.
abstract final class AssistantReauthenticationChallenges {
  static const _lifetime = Duration(minutes: 10);
  static AssistantReauthenticationRequest? _active;
  static DateTime? _issuedAt;

  static AssistantReauthenticationRequest issue(
    AssistantReauthenticationRequest request,
  ) {
    if (!request.isValid) {
      throw ArgumentError.value(
        request,
        'request',
        'Invalid assistant challenge',
      );
    }
    final active = _active;
    final issuedAt = _issuedAt;
    final now = DateTime.now();
    if (active != null &&
        issuedAt != null &&
        now.difference(issuedAt) <= _lifetime) {
      throw StateError('An assistant reauthentication challenge is active');
    }
    _active = request;
    _issuedAt = now;
    return request;
  }

  static bool isActive(Object? candidate) {
    final issuedAt = _issuedAt;
    return candidate is AssistantReauthenticationRequest &&
        identical(candidate, _active) &&
        candidate.isValid &&
        issuedAt != null &&
        DateTime.now().difference(issuedAt) <= _lifetime;
  }

  static void clear(AssistantReauthenticationRequest request) {
    if (identical(request, _active)) {
      _active = null;
      _issuedAt = null;
    }
  }
}
