import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/features/assistant/domain/assistant_envelope.dart';
import 'package:batsh/features/assistant/domain/assistant_message.dart';
import 'package:batsh/features/discovery/data/discovery_repository.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';

void main() {
  test('validated filters map to the existing discovery contract', () {
    final envelope = AssistantEnvelope.fromJson({
      'intent': 'discovery',
      'reply': 'تفضل ترشيحات السباكة في الجيزة',
      'specialty_key': 'plumbing',
      'city_key': 'الجيزة',
    });
    final filters = DiscoveryFilters(
      specialty: envelope.specialtyKey,
      city: envelope.cityKey,
    );

    expect(filters.specialty, 'plumbing');
    expect(filters.city, 'الجيزة');
    expect(filters.isEmpty, isFalse);
  });

  test('assistant messages can carry real ContractorListing values', () {
    const listing = ContractorListing(
      id: 'contractor-123',
      fullName: 'أحمد محمود',
      businessName: 'الأهرام للسباكة والتشطيب',
      specialties: ['plumbing'],
      serviceAreas: ['الجيزة'],
      projectsCompleted: 14,
      reviewCount: 9,
      reviewAvg: 4.8,
      verified: true,
    );
    final message = AssistantMessage(
      id: 'message-1',
      role: AssistantMessageRole.assistant,
      content: 'وجدت لك محترفاً',
      timestamp: DateTime.now(),
      matchingContractors: const [listing],
    );

    expect(message.matchingContractors.single.id, 'contractor-123');
    expect(message.matchingContractors.single.verified, isTrue);
    expect(message.matchingContractors.single.reviewAvg, 4.8);
  });
}
