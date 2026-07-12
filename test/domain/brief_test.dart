import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Brief.fromJson', () {
    test('produces correct fields from a valid JSON map', () {
      final json = <String, dynamic>{
        'id': 'brief-1',
        'homeowner_id': 'ho-1',
        'target_contractor_id': null,
        'apartment_type': 'studio',
        'city': 'القاهرة',
        'district': 'مدينة نصر',
        'work_description': 'دهان شقة كاملة',
        'photo_urls': [],
        'target_specialties': ['paint'],
        'status': 'open',
        'created_at': '2026-06-01T10:00:00.000Z',
      };

      final brief = Brief.fromJson(json);

      expect(brief.id, 'brief-1');
      expect(brief.homeownerId, 'ho-1');
      expect(brief.targetContractorId, isNull);
      expect(brief.apartmentType, ApartmentType.studio);
      expect(brief.city, 'القاهرة');
      expect(brief.district, 'مدينة نصر');
      expect(brief.workDescription, 'دهان شقة كاملة');
      expect(brief.photoUrls, isEmpty);
      expect(brief.targetSpecialties, ['paint']);
      expect(brief.status, BriefStatus.open);
      expect(brief.createdAt, DateTime.utc(2026, 6, 1, 10, 0, 0));
    });

    test('handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'brief-2',
        'homeowner_id': 'ho-2',
        'apartment_type': null,
        'city': 'الجيزة',
        'work_description': 'سباكة',
        'photo_urls': null,
        'target_specialties': null,
        'status': 'cancelled',
        'created_at': '2026-05-15T00:00:00.000Z',
      };

      final brief = Brief.fromJson(json);

      expect(brief.id, 'brief-2');
      expect(brief.targetContractorId, isNull);
      expect(brief.apartmentType, ApartmentType.studio);
      expect(brief.photoUrls, isEmpty);
      expect(brief.targetSpecialties, isEmpty);
      expect(brief.status, BriefStatus.cancelled);
    });

    test('parses target_contractor_id when present', () {
      final json = <String, dynamic>{
        'id': 'brief-3',
        'homeowner_id': 'ho-3',
        'target_contractor_id': 'contractor-1',
        'apartment_type': 'duplex',
        'city': 'الإسكندرية',
        'work_description': 'تشطيب',
        'photo_urls': ['https://example.com/photo.jpg'],
        'target_specialties': ['flooring', 'paint'],
        'status': 'open',
        'created_at': '2026-06-10T00:00:00.000Z',
      };

      final brief = Brief.fromJson(json);

      expect(brief.targetContractorId, 'contractor-1');
      expect(brief.apartmentType, ApartmentType.duplex);
      expect(brief.photoUrls, ['https://example.com/photo.jpg']);
      expect(brief.targetSpecialties, ['flooring', 'paint']);
    });
  });

  group('Brief.isPost', () {
    test('returns true when target_contractor_id is null', () {
      final brief = Brief(
        id: 'b1',
        homeownerId: 'ho-1',
        targetContractorId: null,
        apartmentType: ApartmentType.studio,
        city: 'القاهرة',
        workDescription: 'دهان',
        photoUrls: [],
        targetSpecialties: ['paint'],
        status: BriefStatus.open,
        createdAt: DateTime(2026, 6, 1),
      );

      expect(brief.isPost, isTrue);
    });

    test('returns false when target_contractor_id is set', () {
      final brief = Brief(
        id: 'b2',
        homeownerId: 'ho-1',
        targetContractorId: 'contractor-1',
        apartmentType: ApartmentType.studio,
        city: 'القاهرة',
        workDescription: 'دهان',
        photoUrls: [],
        targetSpecialties: ['paint'],
        status: BriefStatus.open,
        createdAt: DateTime(2026, 6, 1),
      );

      expect(brief.isPost, isFalse);
    });
  });
}
