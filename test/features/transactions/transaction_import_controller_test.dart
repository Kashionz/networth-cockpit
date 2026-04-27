import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/transactions/import/controllers/transaction_import_controller.dart';
import 'package:networth_cockpit/features/transactions/import/models/import_step.dart';

void main() {
  test('starts at card selection with sample review data ready', () {
    final container = _createContainer();
    addTearDown(container.dispose);

    final state = container.read(transactionImportControllerProvider);

    expect(state.currentStep, ImportStep.selectingCard);
    expect(state.selectedCard, isNull);
    expect(state.autoClassifiedCount, 9);
    expect(state.reviewRows, hasLength(5));
    expect(state.reviewRows.first.merchantName, 'NTU TIMS Coffee');
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

      controller.useSampleFile();
      expect(controller.state.currentStep, ImportStep.parsing);

      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);
      expect(controller.state.currentStep, ImportStep.reviewing);

      controller.applyAllSuggestions();
      expect(controller.state.suggestionsApplied, isTrue);
      expect(controller.state.reviewRows, isEmpty);

      controller.confirmCategories();
      expect(controller.state.currentStep, ImportStep.confirming);
      expect(controller.state.writeCount, 14);

      controller.viewWriteSummary();
      expect(controller.state.currentStep, ImportStep.completed);
    },
  );

  test(
    'confirming categories accepts remaining review rows before writing',
    () {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.confirmCategories();

      expect(controller.state.currentStep, ImportStep.confirming);
      expect(controller.state.reviewRows, isEmpty);
      expect(controller.state.acceptedReviewCount, 5);
      expect(controller.state.writeCount, 14);
    },
  );

  test('review rows cannot be mutated outside controller state updates', () {
    final container = _createContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      transactionImportControllerProvider.notifier,
    );

    controller.updateReviewCategory(controller.state.reviewRows.first.id, '交通');

    expect(() => controller.state.reviewRows.clear(), throwsUnsupportedError);
  });

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
    () {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );
      final transactionId = controller.state.reviewRows.first.id;

      controller.updateReviewCategory(transactionId, '交通');

      final updatedState = controller.state;
      expect(updatedState.reviewRows.first.suggestedCategory, '交通');
      expect(updatedState.reviewRows.first.reason, '已記住規則');
      expect(updatedState.writeCount, 14);
    },
  );

  test('exposes lightweight category choices for review rows', () {
    final container = _createContainer();
    addTearDown(container.dispose);

    final state = container.read(transactionImportControllerProvider);

    expect(state.categoryOptions, ['生活', '交通', '訂閱', '固定', '彈性']);
  });

  test('exposes confirm write budget impacts for the imported statement', () {
    final container = _createContainer();
    addTearDown(container.dispose);

    final state = container.read(transactionImportControllerProvider);

    expect(state.budgetImpacts, hasLength(3));
    expect(state.budgetImpacts.map((impact) => impact.label), [
      '固定',
      '生活',
      '彈性',
    ]);
    expect(state.budgetImpacts.map((impact) => impact.amount), [
      2490,
      12860,
      4800,
    ]);
  });

  test(
    'merchant classify fallback keeps local category and writes fallback reason',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        transactionImportControllerProvider.notifier,
      );

      controller.useSampleFile();
      controller.startParsing();
      await _waitForImportStep(container, ImportStep.reviewing);

      final reviewed = controller.state.reviewRows.firstWhere(
        (row) => row.id == 'review-ntu-coffee',
      );
      expect(controller.state.currentStep, ImportStep.reviewing);
      expect(reviewed.suggestedCategory, '生活');
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

      controller.useSampleFile();
      controller.startParsing();
      await delayedClient.firstCallStarted.future;
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

    controller.useSampleFile();
    controller.startParsing();
    await delayedClient.firstCallStarted.future;

    controller.restart();
    delayedClient.release();
    await delayedClient.firstCallFinished.future;
    await Future<void>.microtask(() {});

    final state = container.read(transactionImportControllerProvider);
    expect(state.currentStep, ImportStep.selectingCard);
    expect(state.reviewRows.first.reason, '依商家名稱建議分類');
    expect(state.reviewRows.first.suggestedCategory, '生活');
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
    const Duration(seconds: 1),
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
