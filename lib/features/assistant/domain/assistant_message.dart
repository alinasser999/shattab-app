// Ephemeral in-memory assistant state. It is never persisted or sent as-is.

import 'package:batsh/features/discovery/domain/contractor_listing.dart';

import 'assistant_envelope.dart';

enum AssistantMessageRole { user, assistant }

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.envelope,
    this.matchingContractors = const [],
  });

  final String id;
  final AssistantMessageRole role;
  final String content;
  final DateTime timestamp;
  final AssistantEnvelope? envelope;
  final List<ContractorListing> matchingContractors;

  bool get isUser => role == AssistantMessageRole.user;
  bool get isAssistant => role == AssistantMessageRole.assistant;
}
