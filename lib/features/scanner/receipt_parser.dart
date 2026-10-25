class ParsedReceipt {
  const ParsedReceipt({
    this.merchant,
    this.totalAmount,
    this.receiptDate,
    this.rawOcrText = '',
  });

  final String? merchant;
  final int? totalAmount;
  final DateTime? receiptDate;
  final String rawOcrText;

  bool get hasExtractedFields =>
      merchant != null || totalAmount != null || receiptDate != null;
}

class ReceiptParser {
  const ReceiptParser();

  static final RegExp _datePattern = RegExp(
    r'(?<!\d)(\d{1,4})[./-](\d{1,2})[./-](\d{2,4})(?!\d)',
  );
  static final RegExp _amountPattern = RegExp(
    r'(?<![\d/])(?:\d{1,3}(?:[.,\s]\d{3})+|\d+)(?:[.,]\d{1,2})?(?!\d)',
  );
  static final RegExp _totalLabel = RegExp(
    r'\b(grand\s*total|total\s*(?:amount|payment|due)?|amount\s*due|'
    r'thanh\s*toan|tong\s*(?:thanh\s*toan|cong|tien)|can\s*tra|phai\s*tra)\b',
    caseSensitive: false,
  );
  static final RegExp _excludedLabel = RegExp(
    r'\b(sub\s*total|subtotal|tax|thue|vat|change|tien\s*thua|'
    r'discount|giam\s*gia|cash(?:\s*received)?|tien\s*mat|'
    r'phone|tel|invoice|receipt|order|table)\b',
    caseSensitive: false,
  );
  static final RegExp _merchantNoise = RegExp(
    r'\b(receipt|invoice|tax\s*code|phone|tel|date|cashier|order|'
    r'thank\s*you|welcome|customer|copy|www|https?|email)\b|[@]',
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
      rawOcrText: rawText,
    );
  }

  String? _findMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final foldedLine = _foldDiacritics(line);
      final letters = foldedLine.replaceAll(RegExp(r'[^a-z]'), '');
      if (letters.length < 3 ||
          RegExp(r'^\d').hasMatch(line) ||
          _totalLabel.hasMatch(foldedLine) ||
          _excludedLabel.hasMatch(foldedLine) ||
          _merchantNoise.hasMatch(foldedLine)) {
        continue;
      }
      if (_amountPattern.hasMatch(line) && letters.length < 5) continue;
      return line.replaceAll(RegExp(r'\s{2,}'), ' ');
    }
    return null;
  }

  int? _findTotal(List<String> lines) {
    final matches = <({int priority, int line, int amount})>[];
    for (var index = 0; index < lines.length; index++) {
      final foldedLine = _foldDiacritics(lines[index]);
      if (_excludedLabel.hasMatch(foldedLine)) continue;
      final labelMatch = _totalLabel.firstMatch(foldedLine);
      if (labelMatch == null) continue;

      final sameLine = _amountsIn(lines[index], start: labelMatch.end);
      final candidates = sameLine.isNotEmpty
          ? sameLine
          : index + 1 < lines.length &&
                !_totalLabel.hasMatch(_foldDiacritics(lines[index + 1])) &&
                !_excludedLabel.hasMatch(_foldDiacritics(lines[index + 1]))
          ? _amountsIn(lines[index + 1])
          : const <int>[];
      if (candidates.length != 1) continue;
      final amount = candidates.single;
      if (amount <= 0) continue;

      final label = labelMatch.group(0)!;
      final priority =
          RegExp(
            r'grand|due|tong\s*cong|tong\s*thanh\s*toan|phai\s*tra|can\s*tra',
          ).hasMatch(label)
          ? 0
          : 1;
      matches.add((priority: priority, line: index, amount: amount));
    }
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final priorityOrder = a.priority.compareTo(b.priority);
      return priorityOrder != 0 ? priorityOrder : b.line.compareTo(a.line);
    });
    return matches.first.amount;
  }

  DateTime? _findDate(String text) {
    for (final match in _datePattern.allMatches(text)) {
      final first = int.parse(match.group(1)!);
      final second = int.parse(match.group(2)!);
      final third = int.parse(match.group(3)!);
      final yearFirst = first > 31;
      final year = yearFirst ? first : third;
      final month = second;
      final day = yearFirst ? third : first;
      final normalizedYear = year < 100
          ? year + (year < 70 ? 2000 : 1900)
          : year;
      if (month < 1 || month > 12 || day < 1 || day > 31) continue;
      final date = DateTime(normalizedYear, month, day);
      if (date.year == normalizedYear &&
          date.month == month &&
          date.day == day) {
        return date;
      }
    }
    return null;
  }

  List<int> _amountsIn(String line, {int start = 0}) => _amountPattern
      .allMatches(line.substring(start))
      .map((match) => _parseAmount(match.group(0)!))
      .whereType<int>()
      .toList(growable: false);

  int? _parseAmount(String value) {
    final normalized = value.replaceAll(RegExp(r'\s'), '');
    final dotIndex = normalized.lastIndexOf('.');
    final commaIndex = normalized.lastIndexOf(',');
    final hasBothSeparators = dotIndex >= 0 && commaIndex >= 0;

    if (hasBothSeparators) {
      final lastSeparator = dotIndex > commaIndex ? dotIndex : commaIndex;
      final trailingDigits = normalized.length - lastSeparator - 1;
      if (trailingDigits != 3) return null;
      return int.tryParse(normalized.replaceAll(RegExp(r'[.,]'), ''));
    }
    if (dotIndex >= 0 || commaIndex >= 0) {
      final separatorIndex = dotIndex > commaIndex ? dotIndex : commaIndex;
      final trailingDigits = normalized.length - separatorIndex - 1;
      if (trailingDigits != 3) return null;
      return int.tryParse(normalized.replaceAll(RegExp(r'[.,]'), ''));
    }
    return int.tryParse(normalized);
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
