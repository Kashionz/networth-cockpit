import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/services/ai/l2_analysis_client.dart';
import '../models/import_step.dart';
import '../models/imported_transaction.dart';

final transactionImportControllerProvider =
    NotifierProvider<TransactionImportController, TransactionImportState>(
      TransactionImportController.new,
    );

class TransactionImportController extends Notifier<TransactionImportState> {
  int _parsingOperationId = 0;
  bool _isParsingInFlight = false;

  @override
  TransactionImportState build() => TransactionImportState.initial();

  void selectCard(String cardName) {
    _cancelPendingParsing();
    state = state.copyWith(
      currentStep: ImportStep.uploading,
      selectedCard: cardName,
    );
  }

  void useSampleFile() {
    _cancelPendingParsing();
    state = state.copyWith(currentStep: ImportStep.parsing);
  }

  void startParsing() {
    if (state.currentStep != ImportStep.parsing || _isParsingInFlight) {
      return;
    }
    _isParsingInFlight = true;
    final operationId = ++_parsingOperationId;
    unawaited(_prepareReviewRowsBeforeReviewing(operationId));
  }

  void applyAllSuggestions() {
    state = state.copyWith(
      reviewRows: const [],
      acceptedReviewCount: state.acceptedReviewCount + state.reviewRows.length,
      suggestionsApplied: true,
    );
  }

  void updateReviewCategory(String transactionId, String category) {
    state = state.copyWith(
      reviewRows: [
        for (final row in state.reviewRows)
          if (row.id == transactionId)
            row.copyWith(suggestedCategory: category, reason: '已記住規則')
          else
            row,
      ],
    );
  }

  void confirmCategories() {
    _cancelPendingParsing();
    state = state.copyWith(
      currentStep: ImportStep.confirming,
      reviewRows: const [],
      acceptedReviewCount: state.acceptedReviewCount + state.reviewRows.length,
      suggestionsApplied:
          state.suggestionsApplied || state.reviewRows.isNotEmpty,
    );
  }

  void viewWriteSummary() {
    _cancelPendingParsing();
    state = state.copyWith(currentStep: ImportStep.completed);
  }

  void markFileUnableToParse() {
    _cancelPendingParsing();
    state = state.copyWith(
      currentStep: ImportStep.failed,
      failureTitle: TransactionImportState.unableToParseTitle,
      failureMessage: TransactionImportState.unableToParseMessage,
    );
  }

  void restart() {
    _cancelPendingParsing();
    state = TransactionImportState.initial();
  }

  Future<void> _prepareReviewRowsBeforeReviewing(int operationId) async {
    try {
      final rows = state.reviewRows;
      if (rows.isEmpty) {
        if (!_isParsingResultActive(operationId)) {
          return;
        }
        state = state.copyWith(currentStep: ImportStep.reviewing);
        return;
      }

      final l2Client = ref.read(l2AnalysisClientProvider);
      final nextRows = <ImportedTransaction>[];
      for (final row in rows) {
        if (!_isParsingResultActive(operationId)) {
          return;
        }
        if (!_needsMerchantClassify(row)) {
          nextRows.add(row);
          continue;
        }

        final classified = await l2Client.classifyMerchant(
          merchantName: row.merchantName,
          amount: row.amount,
          fallbackCategory: row.suggestedCategory,
          fallbackConfidence: row.confidence,
        );
        nextRows.add(
          row.copyWith(
            suggestedCategory: classified.category,
            confidence: classified.confidence,
            reason: classified.reason,
          ),
        );
      }

      if (!_isParsingResultActive(operationId)) {
        return;
      }

      state = state.copyWith(
        currentStep: ImportStep.reviewing,
        reviewRows: nextRows,
      );
    } finally {
      _completeParsingOperation(operationId);
    }
  }

  bool _needsMerchantClassify(ImportedTransaction row) {
    return row.newMerchant || row.confidence < 0.86;
  }

  bool _isParsingResultActive(int operationId) {
    return ref.mounted &&
        _isParsingInFlight &&
        operationId == _parsingOperationId &&
        state.currentStep == ImportStep.parsing;
  }

  void _completeParsingOperation(int operationId) {
    if (operationId == _parsingOperationId) {
      _isParsingInFlight = false;
    }
  }

  void _cancelPendingParsing() {
    _parsingOperationId++;
    _isParsingInFlight = false;
  }
}

class TransactionImportState {
  TransactionImportState({
    required this.currentStep,
    required List<ImportedTransaction> reviewRows,
    required this.autoClassifiedCount,
    required this.acceptedReviewCount,
    required this.suggestionsApplied,
    this.selectedCard,
    this.failureTitle,
    this.failureMessage,
  }) : reviewRows = List.unmodifiable(reviewRows);

  factory TransactionImportState.initial() {
    return TransactionImportState(
      currentStep: ImportStep.selectingCard,
      reviewRows: _sampleReviewRows,
      autoClassifiedCount: 9,
      acceptedReviewCount: 0,
      suggestionsApplied: false,
    );
  }

  static const unableToParseTitle = '這份檔案暫時無法解析';
  static const unableToParseMessage = '可以換一份 CSV,或稍後再試';
  static const _categoryOptions = ['生活', '交通', '訂閱', '固定', '彈性'];
  static const _budgetImpacts = [
    BudgetImpact(label: '固定', amount: 2490),
    BudgetImpact(label: '生活', amount: 12860),
    BudgetImpact(label: '彈性', amount: 4800),
  ];

  final ImportStep currentStep;
  final List<ImportedTransaction> reviewRows;
  final int autoClassifiedCount;
  final int acceptedReviewCount;
  final bool suggestionsApplied;
  final String? selectedCard;
  final String? failureTitle;
  final String? failureMessage;

  int get writeCount =>
      autoClassifiedCount + acceptedReviewCount + reviewRows.length;

  List<String> get categoryOptions => _categoryOptions;

  List<BudgetImpact> get budgetImpacts => _budgetImpacts;

  TransactionImportState copyWith({
    ImportStep? currentStep,
    List<ImportedTransaction>? reviewRows,
    int? autoClassifiedCount,
    int? acceptedReviewCount,
    bool? suggestionsApplied,
    String? selectedCard,
    String? failureTitle,
    String? failureMessage,
  }) {
    return TransactionImportState(
      currentStep: currentStep ?? this.currentStep,
      reviewRows: reviewRows ?? this.reviewRows,
      autoClassifiedCount: autoClassifiedCount ?? this.autoClassifiedCount,
      acceptedReviewCount: acceptedReviewCount ?? this.acceptedReviewCount,
      suggestionsApplied: suggestionsApplied ?? this.suggestionsApplied,
      selectedCard: selectedCard ?? this.selectedCard,
      failureTitle: failureTitle ?? this.failureTitle,
      failureMessage: failureMessage ?? this.failureMessage,
    );
  }
}

class BudgetImpact {
  const BudgetImpact({required this.label, required this.amount});

  final String label;
  final num amount;
}

const _sampleReviewRows = [
  ImportedTransaction(
    id: 'review-ntu-coffee',
    merchantName: 'NTU TIMS Coffee',
    amount: 145,
    suggestedCategory: '生活',
    reason: '依商家名稱建議分類',
    confidence: 0.84,
    newMerchant: true,
  ),
  ImportedTransaction(
    id: 'review-taipei-metro',
    merchantName: 'Taipei Metro',
    amount: 320,
    suggestedCategory: '交通',
    reason: '與通勤支出相近',
    confidence: 0.91,
  ),
  ImportedTransaction(
    id: 'review-cloud-storage',
    merchantName: 'Cloud Storage',
    amount: 90,
    suggestedCategory: '訂閱',
    reason: '可能是固定月費',
    confidence: 0.78,
  ),
  ImportedTransaction(
    id: 'review-bookstore-online',
    merchantName: 'Bookstore Online',
    amount: 680,
    suggestedCategory: '彈性',
    reason: '依近期交易樣式建議',
    confidence: 0.72,
    newMerchant: true,
  ),
  ImportedTransaction(
    id: 'review-market-weekend',
    merchantName: 'Market Weekend',
    amount: 1120,
    suggestedCategory: '生活',
    reason: '與日常採買相近',
    confidence: 0.88,
  ),
];
