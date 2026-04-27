import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/cards_repository.dart';
import '../../../../data/repositories/transaction_import_repository.dart';
import '../../../../data/services/ai/l2_analysis_client.dart';
import '../models/import_step.dart';
import '../models/imported_transaction.dart';
import '../services/csv_file_loader.dart';
import '../services/transaction_csv_parser.dart';

final transactionImportControllerProvider =
    NotifierProvider<TransactionImportController, TransactionImportState>(
      TransactionImportController.new,
    );

class TransactionImportController extends Notifier<TransactionImportState> {
  int _parsingOperationId = 0;
  bool _isParsingInFlight = false;
  bool _isWritingInFlight = false;

  @override
  TransactionImportState build() {
    Future<void>(() => _hydrateCardOptions());
    return TransactionImportState.initial();
  }

  void selectCard(dynamic card) {
    final resolvedCard = switch (card) {
      ImportCardOption option => option,
      String name => state.cardOptions.firstWhere(
          (option) => option.name == name,
          orElse: () => ImportCardOption(
            id: 'card-fallback',
            name: name,
            helperText: '臨時卡片',
          ),
        ),
      _ => const ImportCardOption(
          id: 'card-fallback',
          name: '未命名卡片',
          helperText: '臨時卡片',
        ),
    };
    _cancelPendingParsing();
    state = state.copyWith(
      currentStep: ImportStep.uploading,
      selectedCardId: resolvedCard.id,
      selectedCardName: resolvedCard.name,
      pendingCsvContent: null,
      uploadStatusLabel: '等待上傳 CSV',
      transactions: const [],
      reviewTransactionIds: const [],
      completionMessage: null,
      failureTitle: null,
      failureMessage: null,
      skippedRowCount: 0,
      acceptedReviewCount: 0,
      periodStart: null,
      periodEnd: null,
      suggestionsApplied: false,
      usedSupabaseFallback: false,
      isWriting: false,
    );
  }

  void useSampleFile() {
    _stageCsvForParsing(
      csvContent: _sampleCsvContent,
      statusLabel: '已載入範例 CSV，準備解析',
    );
  }

  Future<void> submitCsvPath(String path) async {
    final trimmedPath = path.trim();
    if (trimmedPath.isEmpty) {
      _markUploadIssue('請先輸入 CSV 檔案路徑。');
      return;
    }

    state = state.copyWith(uploadStatusLabel: '正在讀取檔案...');
    final loader = ref.read(csvFileLoaderProvider);
    final result = await loader.load(trimmedPath);
    if (!ref.mounted || state.currentStep != ImportStep.uploading) {
      return;
    }

    if (!result.success || result.content == null) {
      _markUploadIssue(result.message);
      return;
    }

    _stageCsvForParsing(
      csvContent: result.content!,
      statusLabel: '已讀取檔案，準備解析',
    );
  }

  void submitCsvContent(String csvContent) {
    if (csvContent.trim().isEmpty) {
      _markUploadIssue('貼上的內容是空白，請重新貼上 CSV。');
      return;
    }
    _stageCsvForParsing(csvContent: csvContent, statusLabel: '已貼上內容，準備解析');
  }

  void backToUpload() {
    _cancelPendingParsing();
    state = state.copyWith(
      currentStep: ImportStep.uploading,
      uploadStatusLabel: '可重新貼上或重新讀取檔案',
    );
  }

  void startParsing() {
    if (state.currentStep != ImportStep.parsing || _isParsingInFlight) {
      return;
    }
    final csvContent = state.pendingCsvContent;
    if (csvContent == null || csvContent.trim().isEmpty) {
      markFileUnableToParse(message: '尚未取得 CSV 內容，請回上一步重新上傳。');
      return;
    }

    _isParsingInFlight = true;
    final operationId = ++_parsingOperationId;
    state = state.copyWith(uploadStatusLabel: '正在解析與分類...');
    unawaited(_parseAndPrepareReview(operationId, csvContent));
  }

  void applyAllSuggestions() {
    final pendingRows = state.reviewRows;
    if (pendingRows.isEmpty) {
      return;
    }
    state = state.copyWith(
      reviewTransactionIds: const [],
      suggestionsApplied: true,
      acceptedReviewCount: state.acceptedReviewCount + pendingRows.length,
    );
  }

  void updateReviewCategory(String transactionId, String category) {
    final next = [
      for (final row in state.transactions)
        if (row.id == transactionId)
          row.copyWith(
            suggestedCategory: category,
            reason: '已由你調整分類',
            confidence: row.confidence < 0.9 ? 0.9 : row.confidence,
            newMerchant: false,
          )
        else
          row,
    ];

    state = state.copyWith(transactions: next);
  }

  void confirmCategories() {
    _cancelPendingParsing();
    final pendingCount = state.reviewRows.length;
    state = state.copyWith(
      currentStep: ImportStep.confirming,
      reviewTransactionIds: const [],
      suggestionsApplied: state.suggestionsApplied || state.reviewRows.isNotEmpty,
      acceptedReviewCount: state.acceptedReviewCount + pendingCount,
    );
  }

  Future<void> viewWriteSummary() {
    return writeImportedRows();
  }

  Future<void> writeImportedRows() async {
    if (state.currentStep != ImportStep.confirming || _isWritingInFlight) {
      return;
    }
    if (state.transactions.isEmpty) {
      markFileUnableToParse(message: '沒有可寫入的交易，請重新匯入 CSV。');
      return;
    }

    _isWritingInFlight = true;
    state = state.copyWith(isWriting: true);

    final repository = ref.read(transactionImportRepositoryProvider);
    final result = await repository.writeImportedStatement(
      cardId: state.selectedCardId ?? 'card-unknown',
      cardName: state.selectedCardName ?? '未命名卡片',
      periodStart: state.periodStart ?? DateTime.now(),
      periodEnd: state.periodEnd ?? DateTime.now(),
      rows: state.transactions
          .map(
            (row) => TransactionImportWriteRow(
              transactedAt: row.transactedAt,
              amount: row.amount,
              merchant: row.merchantName,
              category: row.suggestedCategory,
              note: row.note,
            ),
          )
          .toList(growable: false),
    );

    _isWritingInFlight = false;
    if (!ref.mounted) {
      return;
    }

    if (!result.completed) {
      markFileUnableToParse(message: result.message);
      state = state.copyWith(isWriting: false);
      return;
    }

    state = state.copyWith(
      currentStep: ImportStep.completed,
      completionMessage: result.message,
      usedSupabaseFallback: result.usedFallback,
      isWriting: false,
    );
  }

  void markFileUnableToParse({String? message}) {
    _cancelPendingParsing();
    state = state.copyWith(
      currentStep: ImportStep.failed,
      failureTitle: TransactionImportState.unableToParseTitle,
      failureMessage: message ?? TransactionImportState.unableToParseMessage,
      isWriting: false,
    );
  }

  void restart() {
    _cancelPendingParsing();
    _isWritingInFlight = false;
    state = TransactionImportState.initial();
    Future<void>(() => _hydrateCardOptions());
  }

  Future<void> _hydrateCardOptions() async {
    final cardsRepository = ref.read(cardsRepositoryProvider);
    final cards = await cardsRepository.fetchCards();
    if (!ref.mounted) {
      return;
    }
    final options = cards
        .map(
          (card) => ImportCardOption(
            id: card.id,
            name: card.displayName,
            helperText: card.maskedNumber ?? '已建立卡片',
          ),
        )
        .toList(growable: false);
    if (options.isNotEmpty) {
      state = state.copyWith(cardOptions: options);
    }
  }

  Future<void> _parseAndPrepareReview(int operationId, String csvContent) async {
    try {
      final parser = ref.read(transactionCsvParserProvider);
      final parseResult = parser.parse(csvContent);
      if (!_isParsingResultActive(operationId)) {
        return;
      }

      if (!parseResult.isSuccess) {
        markFileUnableToParse(message: parseResult.errorMessage);
        return;
      }

      final l2Client = ref.read(l2AnalysisClientProvider);
      final nextRows = <ImportedTransaction>[];
      final reviewIds = <String>[];

      for (final row in parseResult.transactions) {
        if (!_isParsingResultActive(operationId)) {
          return;
        }

        var nextRow = row;
        if (_needsMerchantClassify(row)) {
          final classified = await l2Client.classifyMerchant(
            merchantName: row.merchantName,
            amount: row.amount,
            fallbackCategory: row.suggestedCategory,
            fallbackConfidence: row.confidence,
          );
          nextRow = row.copyWith(
            suggestedCategory: classified.category,
            confidence: classified.confidence,
            reason: classified.reason,
            newMerchant: classified.usedFallback ? row.newMerchant : false,
          );
        }

        nextRows.add(nextRow);
        if (nextRow.requiresReview) {
          reviewIds.add(nextRow.id);
        }
      }

      if (!_isParsingResultActive(operationId)) {
        return;
      }

      state = state.copyWith(
        currentStep: ImportStep.reviewing,
        transactions: nextRows,
        reviewTransactionIds: reviewIds,
        acceptedReviewCount: 0,
        periodStart: parseResult.periodStart,
        periodEnd: parseResult.periodEnd,
        skippedRowCount: parseResult.skippedRowCount,
        suggestionsApplied: false,
        failureTitle: null,
        failureMessage: null,
      );
    } finally {
      _completeParsingOperation(operationId);
    }
  }

  bool _needsMerchantClassify(ImportedTransaction row) {
    return row.newMerchant || row.confidence < 0.86;
  }

  void _stageCsvForParsing({
    required String csvContent,
    required String statusLabel,
  }) {
    _cancelPendingParsing();
    state = state.copyWith(
      currentStep: ImportStep.parsing,
      pendingCsvContent: csvContent,
      uploadStatusLabel: statusLabel,
      failureTitle: null,
      failureMessage: null,
      completionMessage: null,
      transactions: const [],
      reviewTransactionIds: const [],
      acceptedReviewCount: 0,
      skippedRowCount: 0,
      periodStart: null,
      periodEnd: null,
      suggestionsApplied: false,
      usedSupabaseFallback: false,
      isWriting: false,
    );
  }

  void _markUploadIssue(String message) {
    state = state.copyWith(uploadStatusLabel: message);
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
    _parsingOperationId += 1;
    _isParsingInFlight = false;
  }
}

class TransactionImportState {
  TransactionImportState({
    required this.currentStep,
    required List<ImportedTransaction> transactions,
    required List<String> reviewTransactionIds,
    required this.suggestionsApplied,
    required this.acceptedReviewCount,
    required this.skippedRowCount,
    required List<ImportCardOption> cardOptions,
    required this.usedSupabaseFallback,
    required this.isWriting,
    this.selectedCardId,
    this.selectedCardName,
    this.pendingCsvContent,
    this.uploadStatusLabel,
    this.failureTitle,
    this.failureMessage,
    this.completionMessage,
    this.periodStart,
    this.periodEnd,
  }) : transactions = List.unmodifiable(transactions),
       reviewTransactionIds = List.unmodifiable(reviewTransactionIds),
       cardOptions = List.unmodifiable(cardOptions);

  factory TransactionImportState.initial() {
    return TransactionImportState(
      currentStep: ImportStep.selectingCard,
      transactions: const [],
      reviewTransactionIds: const [],
      suggestionsApplied: false,
      acceptedReviewCount: 0,
      skippedRowCount: 0,
      cardOptions: _cardOptions,
      usedSupabaseFallback: false,
      isWriting: false,
      uploadStatusLabel: '等待選擇卡片',
    );
  }

  static const unableToParseTitle = '這份檔案暫時無法解析';
  static const unableToParseMessage = '可以換一份 CSV,或稍後再試';
  static const _categoryOptions = ['固定', '生活', '交通', '訂閱', '彈性', '其他'];
  static const _cardOptions = [
    ImportCardOption(
      id: '11111111-1111-4111-a111-111111111111',
      name: '國泰 CUBE',
      helperText: 'MVP 預設卡片',
    ),
    ImportCardOption(
      id: '22222222-2222-4222-a222-222222222222',
      name: '台新 FlyGo',
      helperText: '可作為第二張卡片測試',
    ),
  ];

  final ImportStep currentStep;
  final List<ImportedTransaction> transactions;
  final List<String> reviewTransactionIds;
  final bool suggestionsApplied;
  final int acceptedReviewCount;
  final int skippedRowCount;
  final List<ImportCardOption> cardOptions;
  final bool usedSupabaseFallback;
  final bool isWriting;
  final String? selectedCardId;
  final String? selectedCardName;
  final String? pendingCsvContent;
  final String? uploadStatusLabel;
  final String? failureTitle;
  final String? failureMessage;
  final String? completionMessage;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  String? get selectedCard => selectedCardName;

  List<String> get categoryOptions => _categoryOptions;

  List<ImportedTransaction> get reviewRows {
    final reviewIdSet = reviewTransactionIds.toSet();
    return [
      for (final row in transactions)
        if (reviewIdSet.contains(row.id)) row,
    ];
  }

  int get autoClassifiedCount => transactions.length - reviewRows.length;

  int get writeCount => transactions.length;

  List<BudgetImpact> get budgetImpacts {
    final totals = <String, num>{};
    for (final row in transactions) {
      totals[row.suggestedCategory] =
          (totals[row.suggestedCategory] ?? 0) + row.amount.abs();
    }
    final entries = totals.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .take(3)
        .map((entry) => BudgetImpact(label: entry.key, amount: entry.value))
        .toList(growable: false);
  }

  TransactionImportState copyWith({
    ImportStep? currentStep,
    List<ImportedTransaction>? transactions,
    List<String>? reviewTransactionIds,
    bool? suggestionsApplied,
    int? acceptedReviewCount,
    int? skippedRowCount,
    List<ImportCardOption>? cardOptions,
    bool? usedSupabaseFallback,
    bool? isWriting,
    Object? selectedCardId = _unset,
    Object? selectedCardName = _unset,
    Object? pendingCsvContent = _unset,
    Object? uploadStatusLabel = _unset,
    Object? failureTitle = _unset,
    Object? failureMessage = _unset,
    Object? completionMessage = _unset,
    Object? periodStart = _unset,
    Object? periodEnd = _unset,
  }) {
    return TransactionImportState(
      currentStep: currentStep ?? this.currentStep,
      transactions: transactions ?? this.transactions,
      reviewTransactionIds: reviewTransactionIds ?? this.reviewTransactionIds,
      suggestionsApplied: suggestionsApplied ?? this.suggestionsApplied,
      acceptedReviewCount: acceptedReviewCount ?? this.acceptedReviewCount,
      skippedRowCount: skippedRowCount ?? this.skippedRowCount,
      cardOptions: cardOptions ?? this.cardOptions,
      usedSupabaseFallback:
          usedSupabaseFallback ?? this.usedSupabaseFallback,
      isWriting: isWriting ?? this.isWriting,
      selectedCardId: selectedCardId == _unset
          ? this.selectedCardId
          : selectedCardId as String?,
      selectedCardName: selectedCardName == _unset
          ? this.selectedCardName
          : selectedCardName as String?,
      pendingCsvContent: pendingCsvContent == _unset
          ? this.pendingCsvContent
          : pendingCsvContent as String?,
      uploadStatusLabel: uploadStatusLabel == _unset
          ? this.uploadStatusLabel
          : uploadStatusLabel as String?,
      failureTitle: failureTitle == _unset
          ? this.failureTitle
          : failureTitle as String?,
      failureMessage: failureMessage == _unset
          ? this.failureMessage
          : failureMessage as String?,
      completionMessage: completionMessage == _unset
          ? this.completionMessage
          : completionMessage as String?,
      periodStart: periodStart == _unset
          ? this.periodStart
          : periodStart as DateTime?,
      periodEnd: periodEnd == _unset ? this.periodEnd : periodEnd as DateTime?,
    );
  }
}

class ImportCardOption {
  const ImportCardOption({
    required this.id,
    required this.name,
    required this.helperText,
  });

  final String id;
  final String name;
  final String helperText;
}

class BudgetImpact {
  const BudgetImpact({required this.label, required this.amount});

  final String label;
  final num amount;
}

const _unset = Object();

const _sampleCsvContent = '''
date,merchant,amount,category,note
2026-04-02,NTU TIMS Coffee,145,生活,早晨咖啡
2026-04-03,Taipei Metro,320,交通,通勤
2026-04-06,Cloud Storage,90,訂閱,雲端空間
2026-04-07,Bookstore Online,680,彈性,線上書店
2026-04-09,Market Weekend,1120,生活,採買
''';
