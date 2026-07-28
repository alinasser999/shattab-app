import 'package:batsh/features/quotes/domain/quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuoteStatus', () {
    test('has expected enum values', () {
      expect(QuoteStatus.values, hasLength(4));
      expect(QuoteStatus.values, contains(QuoteStatus.sent));
      expect(QuoteStatus.values, contains(QuoteStatus.accepted));
      expect(QuoteStatus.values, contains(QuoteStatus.declined));
      expect(QuoteStatus.values, contains(QuoteStatus.withdrawn));
    });

    test('fromString returns correct enum', () {
      expect(QuoteStatus.fromString('sent'), QuoteStatus.sent);
      expect(QuoteStatus.fromString('accepted'), QuoteStatus.accepted);
      expect(QuoteStatus.fromString('declined'), QuoteStatus.declined);
      expect(QuoteStatus.fromString('withdrawn'), QuoteStatus.withdrawn);
    });

    test('fromString defaults to sent for unknown value', () {
      expect(QuoteStatus.fromString('unknown'), QuoteStatus.sent);
    });
  });

  group('Quote.fromJson', () {
    test('produces correct fields from a valid JSON map', () {
      final json = <String, dynamic>{
        'id': 'quote-1',
        'brief_id': 'brief-1',
        'contractor_id': 'contractor-1',
        'price_min': 50000,
        'price_max': 70000,
        'duration_text': 'أسبوعين',
        'note': 'عرض سعر شامل التشطيب',
        'status': 'sent',
        'created_at': '2026-06-01T10:00:00.000Z',
        'updated_at': '2026-06-01T10:00:00.000Z',
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 'quote-1');
      expect(quote.briefId, 'brief-1');
      expect(quote.contractorId, 'contractor-1');
      expect(quote.priceMin, 50000);
      expect(quote.priceMax, 70000);
      expect(quote.durationText, 'أسبوعين');
      expect(quote.note, 'عرض سعر شامل التشطيب');
      expect(quote.status, QuoteStatus.sent);
      expect(quote.createdAt, DateTime.utc(2026, 6, 1, 10, 0, 0));
      expect(quote.updatedAt, DateTime.utc(2026, 6, 1, 10, 0, 0));
    });

    test('handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'quote-2',
        'brief_id': 'brief-2',
        'contractor_id': 'contractor-2',
        'note': 'سعر حسب المعاينة',
        'status': 'accepted',
        'created_at': '2026-06-05T00:00:00.000Z',
        'updated_at': '2026-06-06T00:00:00.000Z',
      };

      final quote = Quote.fromJson(json);

      expect(quote.priceMin, isNull);
      expect(quote.priceMax, isNull);
      expect(quote.durationText, isNull);
      expect(quote.status, QuoteStatus.accepted);
    });

    test('parses declined status', () {
      final json = <String, dynamic>{
        'id': 'quote-3',
        'brief_id': 'brief-3',
        'contractor_id': 'contractor-3',
        'note': 'مرفوض',
        'status': 'declined',
        'created_at': '2026-06-10T00:00:00.000Z',
        'updated_at': '2026-06-10T00:00:00.000Z',
      };

      final quote = Quote.fromJson(json);

      expect(quote.status, QuoteStatus.declined);
    });
  });

  group('Quote.copyWith', () {
    test('returns same instance when no arguments', () {
      final quote = createTestQuote();
      final copy = quote.copyWith();

      expect(copy.id, quote.id);
      expect(copy.priceMin, quote.priceMin);
      expect(copy.priceMax, quote.priceMax);
      expect(copy.durationText, quote.durationText);
      expect(copy.note, quote.note);
      expect(copy.status, quote.status);
    });

    test('produces expected changes when fields are overridden', () {
      final quote = createTestQuote();
      final copy = quote.copyWith(
        priceMin: 80000,
        priceMax: 100000,
        durationText: 'شهر',
        note: 'عرض محدث',
        status: QuoteStatus.accepted,
      );

      expect(copy.priceMin, 80000);
      expect(copy.priceMax, 100000);
      expect(copy.durationText, 'شهر');
      expect(copy.note, 'عرض محدث');
      expect(copy.status, QuoteStatus.accepted);
      expect(copy.id, quote.id);
      expect(copy.briefId, quote.briefId);
      expect(copy.contractorId, quote.contractorId);
    });

    test('keeps original values when copying with null fields', () {
      final quote = createTestQuote(priceMin: null, priceMax: null);
      final copy = quote.copyWith(priceMin: null, priceMax: null);

      expect(copy.priceMin, isNull);
      expect(copy.priceMax, isNull);
    });
  });

  group('Quote computed properties', () {
    test('hasPrice returns true when at least one price is set', () {
      final withMin = createTestQuote(priceMin: 1000, priceMax: null);
      expect(withMin.hasPrice, isTrue);

      final withMax = createTestQuote(priceMin: null, priceMax: 2000);
      expect(withMax.hasPrice, isTrue);

      final none = createTestQuote(priceMin: null, priceMax: null);
      expect(none.hasPrice, isFalse);
    });

    test('isFixedPrice returns true when min equals max', () {
      final fixed = createTestQuote(priceMin: 5000, priceMax: 5000);
      expect(fixed.isFixedPrice, isTrue);

      final range = createTestQuote(priceMin: 5000, priceMax: 7000);
      expect(range.isFixedPrice, isFalse);

      final none = createTestQuote(priceMin: null, priceMax: null);
      expect(none.isFixedPrice, isFalse);
    });
  });
}

Quote createTestQuote({
  String id = 'test-id',
  String briefId = 'test-brief-id',
  String contractorId = 'test-contractor-id',
  int? priceMin = 50000,
  int? priceMax = 70000,
  String? durationText = 'أسبوعين',
  String note = 'عرض سعر',
  QuoteStatus status = QuoteStatus.sent,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => Quote(
  id: id,
  briefId: briefId,
  contractorId: contractorId,
  priceMin: priceMin,
  priceMax: priceMax,
  durationText: durationText,
  note: note,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 6, 1),
  updatedAt: updatedAt ?? DateTime(2026, 6, 1),
);
