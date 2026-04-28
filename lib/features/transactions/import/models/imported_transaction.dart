class ImportedTransaction {
  const ImportedTransaction({
    required this.id,
    required this.transactedAt,
    required this.merchantName,
    required this.amount,
    required this.suggestedCategory,
    required this.reason,
    required this.confidence,
    this.note,
    this.newMerchant = false,
  });

  final String id;
  final DateTime transactedAt;
  final String merchantName;
  final num amount;
  final String suggestedCategory;
  final String reason;
  final double confidence;
  final String? note;
  final bool newMerchant;

  bool get requiresReview => newMerchant || confidence < 0.86;

  ImportedTransaction copyWith({
    String? id,
    DateTime? transactedAt,
    String? merchantName,
    num? amount,
    String? suggestedCategory,
    String? reason,
    double? confidence,
    String? note,
    bool? newMerchant,
  }) {
    return ImportedTransaction(
      id: id ?? this.id,
      transactedAt: transactedAt ?? this.transactedAt,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      reason: reason ?? this.reason,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
      newMerchant: newMerchant ?? this.newMerchant,
    );
  }
}
