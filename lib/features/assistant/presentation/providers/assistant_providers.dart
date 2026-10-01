// Riverpod orchestration for the ephemeral assistant surface.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/analytics/app_analytics.dart';
import 'package:batsh/core/analytics/marketplace_events.dart';
import 'package:batsh/core/supabase/supabase_provider.dart';
import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';

import '../../data/assistant_repository.dart';
import '../../domain/assistant_message.dart';

class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.isThinking = false,
    this.errorMessage,
    this.activeSpecialtyFilter,
    this.activeCityFilter,
  });

  final List<AssistantMessage> messages;
  final bool isThinking;
  final String? errorMessage;
  final String? activeSpecialtyFilter;
  final String? activeCityFilter;

  static const _unset = Object();

  AssistantChatState copyWith({
    List<AssistantMessage>? messages,
    bool? isThinking,
    String? errorMessage,
    bool clearError = false,
    Object? activeSpecialtyFilter = _unset,
    Object? activeCityFilter = _unset,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeSpecialtyFilter: identical(activeSpecialtyFilter, _unset)
          ? this.activeSpecialtyFilter
          : activeSpecialtyFilter as String?,
      activeCityFilter: identical(activeCityFilter, _unset)
          ? this.activeCityFilter
          : activeCityFilter as String?,
    );
  }
}

class AssistantChatNotifier extends Notifier<AssistantChatState> {
  @override
  AssistantChatState build() => const AssistantChatState();

  AssistantRepository get _repository => ref.read(assistantRepositoryProvider);
  DiscoveryRepository get _discoveryRepository =>
      ref.read(discoveryRepositoryProvider);

  Future<void> sendMessage(
    String text, {
    bool resolveContractors = true,
    String audience = 'homeowner',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isThinking) return;

    final userMessage = AssistantMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      role: AssistantMessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    final currentMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: currentMessages,
      isThinking: true,
      clearError: true,
    );

    unawaited(
      AppAnalytics.track(
        MarketplaceEvents.assistantMessageSent,
        properties: {'has_history': currentMessages.length > 1},
      ),
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
    } catch (_) {
      // Keep the UI generic; transport details must not be exposed to users.
      state = state.copyWith(isThinking: false, errorMessage: 'request_failed');
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
