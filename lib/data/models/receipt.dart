class Receipt {
  const Receipt({
    this.id,
    required this.merchant,
    required this.totalAmount,
    required this.receiptDate,
    required this.category,
    this.imagePath,
    this.rawOcrText = '',
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String merchant;
  final int totalAmount;
  final DateTime receiptDate;
  final String category;
  final String? imagePath;
  final String rawOcrText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Receipt copyWith({
    int? id,
    String? merchant,
    int? totalAmount,
    DateTime? receiptDate,
    String? category,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      totalAmount: totalAmount ?? this.totalAmount,
      receiptDate: receiptDate ?? this.receiptDate,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'merchant': merchant,
    'total_amount': totalAmount,
    'receipt_date': _dateOnly(receiptDate),
    'category': category,
    'image_path': imagePath,
    'raw_ocr_text': rawOcrText,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
  };

  factory Receipt.fromMap(Map<String, Object?> map) {
    return Receipt(
      id: map['id'] as int,
      merchant: map['merchant'] as String,
      totalAmount: map['total_amount'] as int,
      receiptDate: DateTime.parse(map['receipt_date'] as String),
      category: map['category'] as String,
      imagePath: map['image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
