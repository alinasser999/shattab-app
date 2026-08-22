import '../../features/auth/domain/profile.dart';
import '../router/routes.dart';

/// Resolves a notification payload to the same destination from every entry
/// point: the in-app inbox, a warm push tap, or a cold-start push tap.
///
/// Payloads are routing hints only. The destination screen still fetches the
/// entity through the normal RLS-protected repository before rendering it.
String? notificationDestination({
  required String? entityType,
  required String? entityId,
  required UserRole? role,
}) {
  final id = entityId?.trim();
  if (id == null || id.isEmpty || role == null) return null;

  return switch (entityType) {
    'brief' =>
      role == UserRole.contractor
          ? Routes.contractorPostDetailPath(id)
          : Routes.homeownerBriefDetailPath(id),
    'post' =>
      role == UserRole.contractor
          ? Routes.contractorCommunityPostPath(id)
          : Routes.homeownerCommunityPostPath(id),
    _ => null,
  };
}
