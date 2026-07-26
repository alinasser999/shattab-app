import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:flutter_test/flutter_test.dart';

Brief _brief({
  DateTime? hiredAt,
  DateTime? completionRequestedAt,
  DateTime? completedAt,
  BriefStatus status = BriefStatus.open,
}) =>
    Brief(
      id: 'b1',
      homeownerId: 'h1',
      apartmentType: ApartmentType.studio,
      city: 'القاهرة',
      workDescription: 'دهان شقة',
      photoUrls: const [],
      targetSpecialties: const ['paint'],
      status: status,
      createdAt: DateTime.utc(2026, 7, 1),
      hiredAt: hiredAt,
      completionRequestedAt: completionRequestedAt,
      completedAt: completedAt,
    );

void main() {
  final t1 = DateTime.utc(2026, 7, 10);
  final t2 = DateTime.utc(2026, 7, 20);
  final t3 = DateTime.utc(2026, 7, 25);

  group('Brief.stage', () {
    test('open before anyone is hired', () {
      expect(_brief().stage, BriefStage.open);
    });

    test('hired once a quote is accepted', () {
      expect(_brief(hiredAt: t1).stage, BriefStage.hired);
    });

    test('completionRequested once the contractor signals done', () {
      expect(
        _brief(hiredAt: t1, completionRequestedAt: t2).stage,
        BriefStage.completionRequested,
      );
    });

    test('completed once the homeowner confirms', () {
      expect(
        _brief(hiredAt: t1, completionRequestedAt: t2, completedAt: t3).stage,
        BriefStage.completed,
      );
    });

    test('homeowner can complete without the contractor requesting first', () {
      expect(
        _brief(hiredAt: t1, completedAt: t3).stage,
        BriefStage.completed,
      );
    });

    // Should be impossible — confirm_completion requires hired_at — but data
    // outlives the code that guarded it, and reporting the furthest state
    // reached beats reporting a finished job as still open.
    test('completed wins even if earlier timestamps are missing', () {
      expect(_brief(completedAt: t3).stage, BriefStage.completed);
      expect(
        _brief(completionRequestedAt: t2).stage,
        BriefStage.completionRequested,
      );
    });
  });

  group('derived flags', () {
    test('canBeReviewed only after completion', () {
      expect(_brief().canBeReviewed, isFalse);
      expect(_brief(hiredAt: t1).canBeReviewed, isFalse);
      expect(
        _brief(hiredAt: t1, completionRequestedAt: t2).canBeReviewed,
        isFalse,
        reason: 'a contractor saying they finished is not proof',
      );
      expect(_brief(hiredAt: t1, completedAt: t3).canBeReviewed, isTrue);
    });

    test('awaitsCompletionConfirmation spans hired and requested only', () {
      expect(_brief().awaitsCompletionConfirmation, isFalse);
      expect(_brief(hiredAt: t1).awaitsCompletionConfirmation, isTrue);
      expect(
        _brief(hiredAt: t1, completionRequestedAt: t2)
            .awaitsCompletionConfirmation,
        isTrue,
      );
      expect(
        _brief(hiredAt: t1, completedAt: t3).awaitsCompletionConfirmation,
        isFalse,
      );
    });

    test('isActive stays false once hired', () {
      expect(_brief().isActive, isTrue);
      expect(_brief(hiredAt: t1).isActive, isFalse);
      expect(_brief(status: BriefStatus.cancelled).isActive, isFalse);
    });
  });

  group('fromJson', () {
    test('parses the completion timestamps', () {
      final brief = Brief.fromJson({
        'id': 'b1',
        'homeowner_id': 'h1',
        'apartment_type': 'studio',
        'city': 'القاهرة',
        'work_description': 'دهان',
        'photo_urls': <String>[],
        'target_specialties': <String>['paint'],
        'status': 'open',
        'created_at': '2026-07-01T00:00:00.000Z',
        'hired_at': '2026-07-10T00:00:00.000Z',
        'completion_requested_at': '2026-07-20T00:00:00.000Z',
        'completed_at': '2026-07-25T00:00:00.000Z',
      });

      expect(brief.stage, BriefStage.completed);
      expect(brief.completedAt, DateTime.parse('2026-07-25T00:00:00.000Z'));
      expect(brief.completionRequestedAt,
          DateTime.parse('2026-07-20T00:00:00.000Z'));
    });

    // Rows written before migration 0019 have neither column.
    test('tolerates rows predating the completion columns', () {
      final brief = Brief.fromJson({
        'id': 'b1',
        'homeowner_id': 'h1',
        'apartment_type': 'studio',
        'city': 'القاهرة',
        'work_description': 'دهان',
        'photo_urls': <String>[],
        'target_specialties': <String>[],
        'status': 'open',
        'created_at': '2026-07-01T00:00:00.000Z',
      });

      expect(brief.completionRequestedAt, isNull);
      expect(brief.completedAt, isNull);
      expect(brief.stage, BriefStage.open);
    });
  });
}
