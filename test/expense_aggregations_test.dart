import 'package:flutter_test/flutter_test.dart';
import 'package:expense_orc/data/models/receipt.dart';
import 'package:expense_orc/features/analytics/expense_aggregations.dart';

Receipt _receipt({
  required int amount,
  required String category,
  required DateTime date,
}) => Receipt(
  merchant: 'Shop',
  totalAmount: amount,
  receiptDate: date,
  category: category,
);

void main() {
  test('aggregates totals for configured categories only', () {
    final totals = categoryExpenseTotals(
      [
        _receipt(
          amount: 100000,
          category: 'Food',
          date: DateTime(2026, 10, 24),
        ),
        _receipt(amount: 25000, category: 'Food', date: DateTime(2026, 10, 24)),
        _receipt(
          amount: 70000,
          category: 'Others',
          date: DateTime(2026, 10, 24),
        ),
      ],
      ['Food', 'Shopping'],
    );

    expect(totals, {'Food': 125000, 'Shopping': 0});
  });

  test('aggregates Monday through Sunday and excludes adjacent weeks', () {
    final totals = weeklyExpenseTotals([
      _receipt(amount: 100, category: 'Food', date: DateTime(2026, 10, 19)),
      _receipt(amount: 200, category: 'Food', date: DateTime(2026, 10, 21)),
      _receipt(amount: 300, category: 'Food', date: DateTime(2026, 10, 21, 18)),
      _receipt(amount: 400, category: 'Food', date: DateTime(2026, 10, 25)),
      _receipt(amount: 500, category: 'Food', date: DateTime(2026, 10, 26)),
    ], dateInWeek: DateTime(2026, 10, 21));

    expect(totals, [100, 0, 500, 0, 0, 0, 400]);
  });
}
