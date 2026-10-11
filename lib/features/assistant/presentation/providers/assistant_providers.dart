// Riverpod orchestration for the ephemeral assistant surface.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/analytics/app_analytics.dart';
import 'package:batsh/core/analytics/marketplace_events.dart';
import 'package:batsh/core/supabase/supabase_provider.dart';
import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';

import '../../data/assistant_repository.dart';
import '../../domain/assistant_failure.dart';
import '../../domain/assistant_message.dart';

class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.isThinking = false,
    this.errorMessage,
    this.failure,
    this.activeSpecialtyFilter,
    this.activeCityFilter,
    this.conversationOwnerUserId,
    this.conversationOwnerRole,
    this.reauthenticatedTurnId,
  });

  final List<AssistantMessage> messages;
  final bool isThinking;
  final String? errorMessage;
  final AssistantFailure? failure;
  final String? activeSpecialtyFilter;
  final String? activeCityFilter;
  final String? conversationOwnerUserId;
  final String? conversationOwnerRole;
  final String? reauthenticatedTurnId;

  static const _unset = Object();

  AssistantChatState copyWith({
    List<AssistantMessage>? messages,
    bool? isThinking,
    String? errorMessage,
    AssistantFailure? failure,
    bool clearError = false,
    Object? activeSpecialtyFilter = _unset,
    Object? activeCityFilter = _unset,
    Object? conversationOwnerUserId = _unset,
    Object? conversationOwnerRole = _unset,
    Object? reauthenticatedTurnId = _unset,
    bool clearReauthenticatedTurn = false,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failure: clearError ? null : (failure ?? this.failure),
      activeSpecialtyFilter: identical(activeSpecialtyFilter, _unset)
          ? this.activeSpecialtyFilter
          : activeSpecialtyFilter as String?,
      activeCityFilter: identical(activeCityFilter, _unset)
          ? this.activeCityFilter
          : activeCityFilter as String?,
      conversationOwnerUserId: identical(conversationOwnerUserId, _unset)
          ? this.conversationOwnerUserId
          : conversationOwnerUserId as String?,
      conversationOwnerRole: identical(conversationOwnerRole, _unset)
          ? this.conversationOwnerRole
          : conversationOwnerRole as String?,
      reauthenticatedTurnId: clearReauthenticatedTurn
          ? null
          : identical(reauthenticatedTurnId, _unset)
          ? this.reauthenticatedTurnId
          : reauthenticatedTurnId as String?,
    );
  }
}

class AssistantChatNotifier extends Notifier<AssistantChatState> {
  @override
  AssistantChatState build() => const AssistantChatState();

  AssistantRepository get _repository => ref.read(assistantRepositoryProvider);
  DiscoveryRepository get _discoveryRepository =>
      ref.read(discoveryRepositoryProvider);

  Future<bool> sendMessage(
    String text, {
    bool resolveContractors = true,
    String audience = 'homeowner',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isThinking) return false;

    final userMessage = AssistantMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      role: AssistantMessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    final currentMessages = [...state.messages, userMessage];

    unawaited(
      AppAnalytics.track(
        MarketplaceEvents.assistantMessageSent,
        properties: {'has_history': currentMessages.length > 1},
      ),
    );

    return _sendMessages(
      currentMessages,
      resolveContractors: resolveContractors,
      audience: audience,
    );
  }

  Future<bool> retryLastMessage({
    bool resolveContractors = true,
    String audience = 'homeowner',
    String? expectedFailedTurnId,
    bool afterReauthentication = false,
  }) async {
    if (state.isThinking) return false;
    final currentMessages = state.messages;
    if (currentMessages.isEmpty ||
        currentMessages.last.role != AssistantMessageRole.user) {
      return false;
    }
    final lastTurnId = currentMessages.last.id;
    final failureType = state.failure?.type;
    final canRetryTemporary =
        failureType == AssistantFailureType.temporaryService &&
        !afterReauthentication;
    final canRetryAuthentication =
        failureType == AssistantFailureType.authenticationRequired &&
        afterReauthentication &&
        state.reauthenticatedTurnId == lastTurnId &&
        expectedFailedTurnId == lastTurnId;
    if (!canRetryTemporary && !canRetryAuthentication) return false;

    return _sendMessages(
      currentMessages,
      resolveContractors: resolveContractors,
      audience: audience,
    );
  }

  bool bindConversationOwner({required String userId, required String role}) {
    if (state.messages.isEmpty) {
      state = state.copyWith(
        conversationOwnerUserId: userId,
        conversationOwnerRole: role,
      );
      return true;
    }
    return state.conversationOwnerUserId == userId &&
        state.conversationOwnerRole == role;
  }

  bool confirmReauthentication({
    required String userId,
    required String role,
    required String failedTurnId,
  }) {
    final lastMessage = state.messages.isEmpty ? null : state.messages.last;
    if (state.isThinking ||
        state.failure?.type != AssistantFailureType.authenticationRequired ||
        state.conversationOwnerUserId != userId ||
        state.conversationOwnerRole != role ||
        lastMessage?.role != AssistantMessageRole.user ||
        lastMessage?.id != failedTurnId) {
      return false;
    }
    state = state.copyWith(reauthenticatedTurnId: failedTurnId);
    return true;
  }

  Future<bool> _sendMessages(
    List<AssistantMessage> currentMessages, {
    required bool resolveContractors,
    required String audience,
  }) async {
    state = state.copyWith(
      messages: currentMessages,
      isThinking: true,
      clearError: true,
      clearReauthenticatedTurn: true,
    );
    try {
      final envelope = await _repository.sendMessage(
        history: currentMessages,
        audience: audience,
      );
      var matchedContractors = <ContractorListing>[];

      if (resolveContractors &&
          (envelope.specialtyKey != null || envelope.cityKey != null)) {
        try {
          final page = await _discoveryRepository.fetchContractorsPage(
            DiscoveryFilters(
              specialty: envelope.specialtyKey,
              city: envelope.cityKey,
            ),
            limit: 3,
          );
          matchedContractors = page.items;
          unawaited(
            AppAnalytics.track(
              MarketplaceEvents.assistantDiscoveryHandoff,
              properties: {
                'has_specialty': envelope.specialtyKey != null,
                'has_city': envelope.cityKey != null,
                'contractors_count': matchedContractors.length,
              },
            ),
          );
        } catch (_) {
          // A discovery outage should not hide the assistant's explanation.
        }
      }

      final assistantMessage = AssistantMessage(
        id: 'a_${DateTime.now().microsecondsSinceEpoch}',
        role: AssistantMessageRole.assistant,
        content: envelope.reply,
        timestamp: DateTime.now(),
        envelope: envelope,
        matchingContractors: matchedContractors,
      );

      state = state.copyWith(
        messages: [...currentMessages, assistantMessage],
        isThinking: false,
        activeSpecialtyFilter: resolveContractors
            ? envelope.specialtyKey
            : null,
        activeCityFilter: resolveContractors ? envelope.cityKey : null,
      );
      return true;
    } on AssistantFailure catch (failure) {
      state = state.copyWith(
        isThinking: false,
        failure: failure,
        errorMessage: failure.type.name,
        clearReauthenticatedTurn: true,
      );
      return false;
    } catch (_) {
      // Keep the UI generic; transport details must not be exposed to users.
      const failure = AssistantFailure(AssistantFailureType.temporaryService);
      state = state.copyWith(
        isThinking: false,
        failure: failure,
        errorMessage: failure.type.name,
        clearReauthenticatedTurn: true,
      );
      return false;
    }
  }

  void clearChat() => state = const AssistantChatState();
}

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(supabase: ref.watch(supabaseClientProvider));
});

final assistantChatProvider =
    NotifierProvider<AssistantChatNotifier, AssistantChatState>(
      AssistantChatNotifier.new,
    );
