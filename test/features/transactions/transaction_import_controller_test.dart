import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/transactions/import/controllers/transaction_import_controller.dart';
import 'package:networth_cockpit/features/transactions/import/models/import_step.dart';

void main() {
  test('starts at card selection with empty draft data ready', () {
    final container = _createContainer();
    addTearDown(container.dispose);

    final state = container.read(transactionImportControllerProvider);

    expect(state.currentStep, ImportStep.selectingCard);
    expect(state.selectedCard, isNull);
    expect(state.transactions, isEmpty);
    expect(state.autoClassifiedCount, 0);
    expect(state.reviewRows, isEmpty);
    expect(state.cardOptions, isNotEmpty);
  });

  test(
    'moves through the MVP import flow from card selection to completed',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.selectCard('國泰 CUBE');
      expect(controller.state.currentStep, ImportStep.uploading);
      expect(controller.state.selectedCard, '國泰 CUBE');

      controller.submitCsvContent(_csvWithCategories);
      expect(controller.state.currentStep, ImportStep.parsing);

      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);
      expect(controller.state.reviewRows, isEmpty);
      expect(controller.state.writeCount, 5);

      controller.confirmCategories();
      expect(controller.state.currentStep, ImportStep.confirming);

      await controller.viewWriteSummary();
      expect(controller.state.currentStep, ImportStep.completed);
      expect(controller.state.completionMessage, isNotEmpty);
    },
  );

  test(
    'confirming categories accepts remaining review rows before writing',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.selectCard('國泰 CUBE');
      controller.submitCsvContent(_csvWithoutCategories);
      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);
      final pendingRows = controller.state.reviewRows.length;

      expect(pendingRows, greaterThan(0));
      controller.confirmCategories();

      expect(controller.state.currentStep, ImportStep.confirming);
      expect(controller.state.reviewRows, isEmpty);
      expect(controller.state.acceptedReviewCount, pendingRows);
      expect(controller.state.writeCount, 5);
    },
  );

  test(
    'transactions cannot be mutated outside controller state updates',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.selectCard('國泰 CUBE');
      controller.submitCsvContent(_csvWithoutCategories);
      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);

      final transactionId = controller.state.reviewRows.first.id;
      controller.updateReviewCategory(transactionId, '交通');

      expect(
        () => controller.state.transactions.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test('failed state exposes calm recovery copy', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      transactionImportControllerProvider.notifier,
    );

    controller.markFileUnableToParse();

    expect(controller.state.currentStep, ImportStep.failed);
    expect(controller.state.failureTitle, '這份檔案暫時無法解析');
    expect(controller.state.failureMessage, '可以換一份 CSV,或稍後再試');
    expect(controller.state.failureTitle, isNot(contains('錯誤')));
    expect(controller.state.failureMessage, isNot(contains('失敗!')));
  });

  test(
    'can update a single review row category without changing write count',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.selectCard('國泰 CUBE');
      controller.submitCsvContent(_csvWithoutCategories);
      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);

      final transactionId = controller.state.reviewRows.first.id;
      controller.updateReviewCategory(transactionId, '交通');

      final updatedState = controller.state;
      expect(
        updatedState.transactions
            .firstWhere((row) => row.id == transactionId)
            .suggestedCategory,
        '交通',
      );
      expect(
        updatedState.transactions
            .firstWhere((row) => row.id == transactionId)
            .reason,
        '已由你調整分類',
      );
      expect(updatedState.writeCount, 5);
    },
  );

  test('exposes lightweight category choices for review rows', () {
    final container = _createContainer();
    addTearDown(container.dispose);

    final state = container.read(transactionImportControllerProvider);

    expect(state.categoryOptions, ['固定', '生活', '交通', '訂閱', '彈性', '其他']);
  });

  test(
    'exposes confirm write budget impacts for the imported statement',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.selectCard('國泰 CUBE');
      controller.submitCsvContent(_csvWithCategories);
      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);

      final state = controller.state;
      expect(state.budgetImpacts, hasLength(3));
      expect(state.budgetImpacts.map((impact) => impact.label), [
        '生活',
        '彈性',
        '交通',
      ]);
      expect(state.budgetImpacts.map((impact) => impact.amount), [
        1265,
        680,
        320,
      ]);
    },
  );

  test(
    'merchant classify fallback keeps local category and writes fallback reason',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.selectCard('國泰 CUBE');
      controller.submitCsvContent(_csvWithoutCategories);
      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);

      final reviewed = controller.state.transactions.firstWhere(
        (row) => row.merchantName == 'Bookstore Online',
      );
      expect(controller.state.currentStep, ImportStep.reviewing);
      expect(reviewed.suggestedCategory, '彈性');
      expect(reviewed.reason, contains('保留本地分類'));
    },
  );

  test(
    'startParsing ignores re-entry while one parsing operation is in flight',
    () async {
      final delayedClient = _DelayedL2Client();
      final container = _createContainer(client: delayedClient);
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.selectCard('國泰 CUBE');
      controller.submitCsvContent(_csvWithoutCategories);
      controller.startParsing();
      await delayedClient.firstCallStarted.future.timeout(
        const Duration(seconds: 2),
      );
      controller.startParsing();

      expect(delayedClient.callCount, 1);

      delayedClient.release();
      await _waitForImportStep(container, ImportStep.reviewing);
    },
  );

  test('stale async parsing result is discarded after restart', () async {
    final delayedClient = _DelayedL2Client();
    final container = _createContainer(client: delayedClient);
    addTearDown(container.dispose);
    final controller = container.read(
      transactionImportControllerProvider.notifier,
    );

    controller.selectCard('國泰 CUBE');
    controller.submitCsvContent(_csvWithoutCategories);
    controller.startParsing();
    await delayedClient.firstCallStarted.future.timeout(
      const Duration(seconds: 2),
    );

    controller.restart();
    delayedClient.release();
    await delayedClient.firstCallFinished.future.timeout(
      const Duration(seconds: 2),
    );
    await Future<void>.microtask(() {});

    final state = container.read(transactionImportControllerProvider);
    expect(state.currentStep, ImportStep.selectingCard);
    expect(state.transactions, isEmpty);
    expect(state.selectedCard, isNull);
  });
}

ProviderContainer _createContainer({L2AnalysisClient? client}) {
  return ProviderContainer(
    overrides: [
      l2AnalysisClientProvider.overrideWithValue(
        client ?? _StaticFallbackL2Client(),
      ),
    ],
  );
}

Future<void> _waitForImportStep(
  ProviderContainer container,
  ImportStep step,
) async {
  if (container.read(transactionImportControllerProvider).currentStep == step) {
    return;
  }

  final completer = Completer<void>();
  late final ProviderSubscription<TransactionImportState> subscription;
  subscription = container.listen(transactionImportControllerProvider, (
    previous,
    next,
  ) {
    if (!completer.isCompleted && next.currentStep == step) {
      completer.complete();
      subscription.close();
    }
  });

  await completer.future.timeout(
    const Duration(seconds: 3),
    onTimeout: () {
      subscription.close();
      throw TestFailure('Timed out waiting for step: $step');
    },
  );
}

class _StaticFallbackL2Client extends L2AnalysisClient {
  _StaticFallbackL2Client()
    : super(
        baseUrl: null,
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );

  @override
  Future<MerchantClassificationResult> classifyMerchant({
    required String merchantName,
    required num amount,
    required String fallbackCategory,
    required double fallbackConfidence,
  }) async {
    return MerchantClassificationResult(
      category: fallbackCategory,
      confidence: fallbackConfidence,
      reason: '商家分類服務暫時不可用，保留本地分類。',
      source: L2ResultSource.fallback,
    );
  }
}

class _DelayedL2Client extends _StaticFallbackL2Client {
  final firstCallStarted = Completer<void>();
  final firstCallFinished = Completer<void>();
  final _releaseGate = Completer<void>();
  int callCount = 0;

  void release() {
    if (!_releaseGate.isCompleted) {
      _releaseGate.complete();
    }
  }

  @override
  Future<MerchantClassificationResult> classifyMerchant({
    required String merchantName,
    required num amount,
    required String fallbackCategory,
    required double fallbackConfidence,
  }) async {
    callCount += 1;
    if (!firstCallStarted.isCompleted) {
      firstCallStarted.complete();
    }

    await _releaseGate.future;

    if (!firstCallFinished.isCompleted) {
      firstCallFinished.complete();
    }

    return MerchantClassificationResult(
      category: fallbackCategory,
      confidence: fallbackConfidence,
      reason: '商家分類服務暫時不可用，保留本地分類。',
      source: L2ResultSource.fallback,
    );
  }
}

const _csvWithCategories = '''
date,merchant,amount,category,note
2026-04-02,NTU TIMS Coffee,145,生活,早晨咖啡
2026-04-03,Taipei Metro,320,交通,通勤
2026-04-06,Cloud Storage,90,訂閱,雲端空間
2026-04-07,Bookstore Online,680,彈性,線上書店
2026-04-09,Market Weekend,1120,生活,採買
''';

const _csvWithoutCategories = '''
date,merchant,amount,note
2026-04-02,NTU TIMS Coffee,145,早晨咖啡
2026-04-03,Taipei Metro,320,通勤
2026-04-06,Cloud Storage,90,雲端空間
2026-04-07,Bookstore Online,680,線上書店
2026-04-09,Market Weekend,1120,採買
''';
