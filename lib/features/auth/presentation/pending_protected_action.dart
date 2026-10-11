import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/draft_photo.dart';
import '../../../core/router/routes.dart';
import '../domain/profile.dart';

final pendingProtectedActionCoordinatorProvider =
    Provider<PendingProtectedActionCoordinator>((ref) {
      final coordinator = PendingProtectedActionCoordinator();
      ref.onDispose(coordinator.dispose);
      return coordinator;
    });

/// A serializable-in-memory description of a guest action. The action is
/// restored from this data after auth routing replaces the original page;
/// it never stores a widget, BuildContext, or callback.
sealed class PendingProtectedAction {
  const PendingProtectedAction({this.id = ''});

  final String id;
  String get resumeLocation;
  String get redirectLocation => resumeLocation;
  PendingProtectedAction withId(String id);
}

class AssistantSendAction extends PendingProtectedAction {
  const AssistantSendAction({super.id = '', required this.text});

  final String text;

  @override
  String get resumeLocation => Routes.homeownerAssistant;

  @override
  AssistantSendAction withId(String id) =>
      AssistantSendAction(id: id, text: text);
}

class ProjectPublishDraft {
  const ProjectPublishDraft({
    required this.title,
    required this.description,
    required this.area,
    required this.budget,
    required this.service,
    required this.apartmentType,
    required this.city,
    required this.district,
    required this.startTiming,
    required this.budgetUndecided,
    required this.publishKey,
    this.publishFingerprint,
    required this.step,
    required this.photos,
  });

  final String title;
  final String description;
  final String area;
  final String budget;
  final String? service;
  final String? apartmentType;
  final String? city;
  final String? district;
  final String startTiming;
  final bool budgetUndecided;
  final String publishKey;
  final String? publishFingerprint;
  final int step;
  final List<DraftPhoto> photos;

  Map<String, dynamic> toStore({required String ownerId}) => {
    'title': title,
    'description': description,
    'area': area,
    'budget': budget,
    'service': service,
    'apartment_type': apartmentType,
    'city': city,
    'district': district,
    'start_timing': startTiming,
    'budget_undecided': budgetUndecided,
    'publish_key': publishKey,
    if (publishFingerprint != null) 'publish_fingerprint': publishFingerprint,
    'owner_id': ownerId,
  };
}

class ProjectPublishAction extends PendingProtectedAction {
  const ProjectPublishAction({super.id = '', required this.draft});

  final ProjectPublishDraft draft;

  @override
  String get resumeLocation => Routes.homeownerNewPost;

  @override
  ProjectPublishAction withId(String id) =>
      ProjectPublishAction(id: id, draft: draft);
}

class DirectBriefDraft {
  const DirectBriefDraft({
    required this.description,
    required this.apartmentType,
    required this.city,
    required this.district,
    required this.photos,
  });

  final String description;
  final String? apartmentType;
  final String? city;
  final String? district;
  final List<DraftPhoto> photos;

  Map<String, dynamic> toStore() => {
    'description': description,
    'apartment_type': apartmentType,
    'city': city,
    'district': district,
  };
}

class DirectBriefSendAction extends PendingProtectedAction {
  const DirectBriefSendAction({
    super.id = '',
    required this.contractorId,
    required this.draft,
  });

  final String contractorId;
  final DirectBriefDraft draft;

  @override
  String get resumeLocation => Routes.homeownerSendBriefPath(contractorId);

  @override
  DirectBriefSendAction withId(String id) =>
      DirectBriefSendAction(id: id, contractorId: contractorId, draft: draft);
}

class ExploreFeedRefreshAction extends PendingProtectedAction {
  const ExploreFeedRefreshAction({super.id = '', this.filter = 'all'});

  final String filter;

  @override
  String get resumeLocation => Routes.homeownerExplore;

  @override
  ExploreFeedRefreshAction withId(String id) =>
      ExploreFeedRefreshAction(id: id, filter: filter);
}

class ExplorePostLaunchAction extends PendingProtectedAction {
  const ExplorePostLaunchAction({super.id = '', this.kindRouteValue});

  /// Null keeps the existing post-type chooser as the resumed destination.
  /// Otherwise the exact post type is carried to the composer route.
  final String? kindRouteValue;

  bool get opensTypeChooser => kindRouteValue == null;

  @override
  String get resumeLocation => opensTypeChooser
      ? Routes.homeownerExplore
      : Routes.homeownerExploreCreatePost;

  @override
  String get redirectLocation => kindRouteValue == null
      ? Routes.homeownerExplore
      : '${Routes.homeownerExploreCreatePost}?type=${Uri.encodeQueryComponent(kindRouteValue!)}';

  @override
  ExplorePostLaunchAction withId(String id) =>
      ExplorePostLaunchAction(id: id, kindRouteValue: kindRouteValue);
}

/// One in-flight guest action for the app. Its lifetime is the ProviderScope,
/// so router redirects can dispose the original route without losing intent.
class PendingProtectedActionCoordinator extends ChangeNotifier {
  PendingProtectedAction? _action;
  String? _userId;
  bool _awaitingOnboarding = false;
  bool _claimed = false;
  bool _sheetOpen = false;
  int _sequence = 0;

  PendingProtectedAction? get action => _action;

  PendingProtectedAction? capture(PendingProtectedAction action) {
    if (_action != null) {
      if (_claimed || _sheetOpen || _awaitingOnboarding) return null;
      // A later explicit action abandons a released failure intent. It can
      // never redirect or dispatch by itself.
      clear();
    }
    final captured = action.withId(
      '${DateTime.now().microsecondsSinceEpoch}-${++_sequence}',
    );
    _action = captured;
    _userId = null;
    _awaitingOnboarding = false;
    _claimed = false;
    _sheetOpen = true;
    notifyListeners();
    return captured;
  }

  bool get awaitingOnboarding => _awaitingOnboarding;

  bool isAwaitingOnboarding(String actionId) =>
      _action?.id == actionId && _awaitingOnboarding;

  bool isClaimed(String actionId) => _action?.id == actionId && _claimed;

  bool isReleasedRetryable(String actionId) =>
      _action?.id == actionId &&
      !_claimed &&
      !_sheetOpen &&
      !_awaitingOnboarding;

  void markOtpCompletedAwaitingOnboarding(String actionId, String userId) {
    if (_action?.id != actionId || !_sheetOpen) return;
    _markAwaitingOnboarding(actionId, userId);
  }

  /// Retains an action explicitly captured by a signed-in user whose profile
  /// still needs onboarding. This path is separate from an auth-sheet
  /// dismissal or from a released action after an operation failure.
  void markSignedInAwaitingOnboarding(String actionId, String userId) {
    if (_action?.id != actionId || !_sheetOpen) return;
    _markAwaitingOnboarding(actionId, userId);
  }

  void _markAwaitingOnboarding(String actionId, String userId) {
    if (_action?.id != actionId) return;
    if (_userId != null && _userId != userId) {
      clear();
      return;
    }
    _userId ??= userId;
    _awaitingOnboarding = true;
    _claimed = false;
    _sheetOpen = false;
    notifyListeners();
  }

  void observeSession(String? userId) {
    if (_action == null) return;
    if (userId == null) {
      if (_userId != null) clear();
      return;
    }
    if (_userId != null && userId != _userId) {
      clear();
      return;
    }
    if (_userId == null) {
      _userId = userId;
      notifyListeners();
    }
  }

  void observeProfile(Profile? profile, {required String? sessionUserId}) {
    if (_action == null || sessionUserId == null) return;
    if (_userId != null && _userId != sessionUserId) {
      clear();
      return;
    }
    _userId ??= sessionUserId;
    if (profile == null || profile.id != sessionUserId) return;
    if (profile.role == UserRole.contractor) {
      clear();
    }
  }

  bool isEligibleHomeowner(Profile? profile, {String? userId}) =>
      profile != null &&
      (userId == null || profile.id == userId) &&
      profile.roleSelectionLocked &&
      profile.role == UserRole.homeowner &&
      profile.onboardingComplete &&
      profile.fullName.trim().length >= 2;

  bool claim(
    String actionId, {
    required String? sessionUserId,
    required Profile? profile,
  }) {
    if (_action?.id != actionId || sessionUserId == null) return false;
    if (_userId != null && _userId != sessionUserId) {
      clear();
      return false;
    }
    if (!isEligibleHomeowner(profile, userId: sessionUserId) || _claimed) {
      return false;
    }
    _userId ??= sessionUserId;
    _claimed = true;
    _awaitingOnboarding = false;
    _sheetOpen = false;
    notifyListeners();
    return true;
  }

  T? resumable<T extends PendingProtectedAction>(
    String location, {
    required String? sessionUserId,
    required Profile? profile,
  }) {
    final pending = _action;
    if (pending is! T ||
        pending.resumeLocation != location ||
        _claimed ||
        _sheetOpen ||
        !_awaitingOnboarding) {
      return null;
    }
    if (!isEligibleHomeowner(profile, userId: sessionUserId) ||
        sessionUserId == null) {
      return null;
    }
    if (_userId != null && _userId != sessionUserId) {
      clear();
      return null;
    }
    _userId ??= sessionUserId;
    return pending;
  }

  String? redirectForReadyHomeowner(
    String location, {
    required String? sessionUserId,
    required Profile profile,
  }) {
    final pending = _action;
    if (pending == null) return null;
    if (_sheetOpen || _claimed || !_awaitingOnboarding) return null;
    if (profile.role != UserRole.homeowner) {
      clear();
      return null;
    }
    if (!isEligibleHomeowner(profile, userId: sessionUserId) ||
        sessionUserId == null) {
      return null;
    }
    if (_userId != null && _userId != sessionUserId) {
      clear();
      return null;
    }
    _userId ??= sessionUserId;
    return location == pending.resumeLocation ? null : pending.redirectLocation;
  }

  void release(String actionId) {
    if (_action?.id != actionId || !_claimed) return;
    _claimed = false;
    notifyListeners();
  }

  /// Discards a completed gate's released retry intent when the user starts a
  /// different ordinary action. Active gates and onboarding intents are kept.
  bool discardReleased(String actionId) {
    if (_action?.id != actionId ||
        _claimed ||
        _sheetOpen ||
        _awaitingOnboarding) {
      return false;
    }
    clear();
    return true;
  }

  void complete(String actionId) {
    if (_action?.id == actionId) clear();
  }

  void clear() {
    if (_action == null) return;
    _action = null;
    _userId = null;
    _awaitingOnboarding = false;
    _claimed = false;
    _sheetOpen = false;
    notifyListeners();
  }
}
