class ImportedTransaction {
  const ImportedTransaction({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.suggestedCategory,
    required this.reason,
    required this.confidence,
    this.newMerchant = false,
  });

  final String id;
  final String merchantName;
  final num amount;
  final String suggestedCategory;
  final String reason;
  final double confidence;
  final bool newMerchant;

  bool get requiresReview => newMerchant || confidence < 0.86;

  ImportedTransaction copyWith({
    String? id,
    String? merchantName,
    num? amount,
    String? suggestedCategory,
    String? reason,
    double? confidence,
    bool? newMerchant,
  }) {
    return ImportedTransaction(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      reason: reason ?? this.reason,
      confidence: confidence ?? this.confidence,
      newMerchant: newMerchant ?? this.newMerchant,
    );
  }
}
