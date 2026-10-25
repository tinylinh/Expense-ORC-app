import 'package:flutter_test/flutter_test.dart';
import 'package:expense_orc/features/scanner/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    const parser = ReceiptParser();

    test('extracts merchant, total and day-first date', () {
      final result = parser.parse('''
ABC COFFEE
12/10/2026
Subtotal: 100.000 VND
Tax: 10.000 VND
TOTAL: 125,000 VND
''');

      expect(result.merchant, 'ABC COFFEE');
      expect(result.totalAmount, 125000);
      expect(result.receiptDate, DateTime(2026, 10, 12));
      expect(result.rawOcrText, contains('ABC COFFEE'));
    });

    test('prioritizes grand total over other labeled totals', () {
      final result = parser.parse('''
Shop One
TOTAL: 120.000
GRAND TOTAL: 99.500
''');

      expect(result.totalAmount, 99500);
    });

    test('recognizes Vietnamese total labels with diacritics', () {
      final result = parser.parse('''
CỬA HÀNG ABC
Thuế: 10.000
TỔNG THANH TOÁN: 135.000 VNĐ
''');

      expect(result.merchant, 'CỬA HÀNG ABC');
      expect(result.totalAmount, 135000);
    });

    test('recognizes unaccented Vietnamese payment labels', () {
      expect(parser.parse('SHOP ABC\nthanh toan: 150000').totalAmount, 150000);
      expect(
        parser.parse('SHOP ABC\ntong tien: 150,000 đ').totalAmount,
        150000,
      );
      expect(parser.parse('SHOP ABC\nTỔNG CỘNG: 150.000').totalAmount, 150000);
    });

    test('supports amounts with currency markers and nearby lines', () {
      expect(parser.parse('SHOP ABC\nTOTAL: 150.000 đ').totalAmount, 150000);
      expect(
        parser.parse('SHOP ABC\nGRAND TOTAL\n150,000 VND').totalAmount,
        150000,
      );
      expect(parser.parse('SHOP ABC\nAMOUNT DUE: 150000').totalAmount, 150000);
    });

    test(
      'prefers the strongest total label and excludes cash and discounts',
      () {
        final result = parser.parse('''
Market ABC
TOTAL: 120.000
CASH RECEIVED: 200.000
CHANGE: 80.000
GRAND TOTAL: 99.500
''');

        expect(result.totalAmount, 99500);
      },
    );

    test('does not mistake subtotal for the final total', () {
      final result = parser.parse('''
Market ABC
Subtotal: 500.000
VAT: 50.000
Change: 20.000
''');

      expect(result.totalAmount, isNull);
    });

    test(
      'does not infer a total from unrelated numbers or ambiguous decimals',
      () {
        expect(parser.parse('SHOP ABC\nPhone: 0901234567').totalAmount, isNull);
        expect(parser.parse('SHOP ABC\nTOTAL: 1,234.56').totalAmount, isNull);
        expect(parser.parse('SHOP ABC\nTOTAL: 150.50').totalAmount, isNull);
      },
    );

    test('normalizes ISO dates and rejects impossible dates', () {
      expect(
        parser.parse('Store\n2026-10-12').receiptDate,
        DateTime(2026, 10, 12),
      );
      expect(parser.parse('Store\n31/02/2026').receiptDate, isNull);
      expect(
        parser.parse('Store\n24-10-2026').receiptDate,
        DateTime(2026, 10, 24),
      );
      expect(
        parser.parse('Store\n2026/10/24').receiptDate,
        DateTime(2026, 10, 24),
      );
    });

    test('leaves unrecognized fields empty for manual review', () {
      final result = parser.parse('RECEIPT\nThank you');

      expect(result.merchant, isNull);
      expect(result.totalAmount, isNull);
      expect(result.receiptDate, isNull);
    });
  });
}
