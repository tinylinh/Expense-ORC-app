import '../../data/models/receipt.dart';

Map<String, int> categoryExpenseTotals(
  Iterable<Receipt> receipts,
  Iterable<String> categories,
) {
  final totals = {for (final category in categories) category: 0};
  for (final receipt in receipts) {
    if (totals.containsKey(receipt.category)) {
      totals[receipt.category] =
          totals[receipt.category]! + receipt.totalAmount;
    }
  }
  return totals;
}

List<int> weeklyExpenseTotals(
  Iterable<Receipt> receipts, {
  required DateTime dateInWeek,
}) {
  final date = DateTime.utc(dateInWeek.year, dateInWeek.month, dateInWeek.day);
  final monday = date.subtract(Duration(days: date.weekday - 1));
  final totals = List<int>.filled(7, 0);
  for (final receipt in receipts) {
    final receiptDate = DateTime.utc(
      receipt.receiptDate.year,
      receipt.receiptDate.month,
      receipt.receiptDate.day,
    );
    final dayIndex = receiptDate.difference(monday).inDays;
    if (dayIndex >= 0 && dayIndex < totals.length) {
      totals[dayIndex] += receipt.totalAmount;
    }
  }
  return totals;
}
