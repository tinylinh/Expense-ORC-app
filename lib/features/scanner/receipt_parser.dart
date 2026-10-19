class ParsedReceipt {
  const ParsedReceipt({this.merchant, this.totalAmount, this.receiptDate});

  final String? merchant;
  final int? totalAmount;
  final DateTime? receiptDate;

  bool get hasExtractedFields =>
      merchant != null || totalAmount != null || receiptDate != null;
}

class ReceiptParser {
  const ReceiptParser();

  static final RegExp _datePattern = RegExp(
    r'\b(\d{1,4})[./-](\d{1,2})[./-](\d{2,4})\b',
  );
  static final RegExp _amountPattern = RegExp(
    r'(?<!\d)(?:\d{1,3}(?:[.,\s]\d{3})+|\d+)(?:[.,]\d{1,2})?(?!\d)',
  );
  static final RegExp _totalLabel = RegExp(
    r'\b(grand\s*total|total\s*due|amount\s*due|total|thanh\s*toan|tong\s*(thanh\s*toan|cong|tien)|can\s*tra|phai\s*tra)\b',
    caseSensitive: false,
  );
  static final RegExp _excludeTotal = RegExp(
    r'\b(sub\s*total|subtotal|tax|thue|vat|change|tien\s*thua|discount|saving)\b',
    caseSensitive: false,
  );

  ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return ParsedReceipt(
      merchant: _findMerchant(lines),
      totalAmount: _findTotal(lines),
      receiptDate: _findDate(rawText),
    );
  }

  String? _findMerchant(List<String> lines) {
    for (final line in lines.take(7)) {
      final foldedLine = _foldDiacritics(line);
      final letters = foldedLine.replaceAll(RegExp(r'[^A-Za-z]'), '');
      if (letters.length < 3 ||
          RegExp(r'^\d').hasMatch(line) ||
          _totalLabel.hasMatch(foldedLine) ||
          _excludeTotal.hasMatch(foldedLine) ||
          RegExp(
            r'(receipt|invoice|tax\s*code|phone|tel|date|cashier|order|thank\s*you|welcome|customer|copy|www\.|https?://|@)',
            caseSensitive: false,
          ).hasMatch(foldedLine)) {
        continue;
      }
      if (_amountPattern.hasMatch(line) && letters.length < 5) continue;
      return line.replaceAll(RegExp(r'\s{2,}'), ' ');
    }
    return null;
  }

  int? _findTotal(List<String> lines) {
    final matches = <({int priority, int amount})>[];
    for (final line in lines) {
      final foldedLine = _foldDiacritics(line);
      if (_excludeTotal.hasMatch(foldedLine)) continue;
      final labelMatch = _totalLabel.firstMatch(foldedLine);
      if (labelMatch == null) continue;
      final amount = _amountsIn(line).lastOrNull;
      if (amount == null || amount <= 0) continue;
      final label = labelMatch.group(0)!;
      final priority =
          label.contains('grand') ||
              label.contains('due') ||
              label.contains('tong cong') ||
              label.contains('tong thanh toan') ||
              label.contains('phai tra') ||
              label.contains('can tra')
          ? 0
          : 1;
      matches.add((priority: priority, amount: amount));
    }
    if (matches.isEmpty) return null;
    matches.sort((a, b) => a.priority.compareTo(b.priority));
    return matches.first.amount;
  }

  DateTime? _findDate(String text) {
    for (final match in _datePattern.allMatches(text)) {
      final first = int.parse(match.group(1)!);
      final second = int.parse(match.group(2)!);
      var third = int.parse(match.group(3)!);
      int year;
      int month;
      int day;
      if (first > 31) {
        year = first;
        month = second;
        day = third;
      } else {
        day = first;
        month = second;
        year = third;
      }
      if (year < 100) year += year < 70 ? 2000 : 1900;
      if (month < 1 || month > 12 || day < 1 || day > 31) continue;
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    }
    return null;
  }

  List<int> _amountsIn(String line) => _amountPattern
      .allMatches(line)
      .map((match) => _parseAmount(match.group(0)!))
      .whereType<int>()
      .toList(growable: false);

  int? _parseAmount(String value) {
    var normalized = value.replaceAll(RegExp(r'\s'), '');
    final dotIndex = normalized.lastIndexOf('.');
    final commaIndex = normalized.lastIndexOf(',');
    final decimalIndex = dotIndex > commaIndex ? dotIndex : commaIndex;
    if (dotIndex >= 0 && commaIndex >= 0) {
      final decimalDigits = normalized.length - decimalIndex - 1;
      if (decimalDigits <= 2) {
        normalized =
            '${normalized.substring(0, decimalIndex).replaceAll(RegExp(r'[.,]'), '')}.'
            '${normalized.substring(decimalIndex + 1)}';
      } else {
        normalized = normalized.replaceAll(RegExp(r'[.,]'), '');
      }
    } else if (decimalIndex >= 0) {
      final digitsAfter = normalized.length - decimalIndex - 1;
      if (digitsAfter == 3) {
        normalized = normalized.replaceAll(RegExp(r'[.,]'), '');
      } else {
        normalized = normalized.replaceAll(',', '.');
      }
    }
    final number = double.tryParse(normalized);
    if (number == null || !number.isFinite) return null;
    return number.round();
  }

  String _foldDiacritics(String value) {
    var result = value.toLowerCase();
    const characters = {
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'e': 'éèẻẽẹêếềểễệ',
      'i': 'íìỉĩị',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'u': 'úùủũụưứừửữự',
      'y': 'ýỳỷỹỵ',
      'd': 'đ',
    };
    for (final entry in characters.entries) {
      result = result.replaceAll(RegExp('[${entry.value}]'), entry.key);
    }
    return result;
  }
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
