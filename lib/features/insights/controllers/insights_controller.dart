import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/ai/l2_analysis_client.dart';
import '../../../shared/models/month_key.dart';
import '../models/monthly_insight.dart';

final insightsControllerProvider =
    NotifierProvider<InsightsController, InsightsState>(InsightsController.new);

class InsightsController extends Notifier<InsightsState> {
  @override
  InsightsState build() {
    const fallback = _mockMonthlyInsight;
    unawaited(refresh(seed: fallback));
    return const InsightsState(
      fallbackInsight: fallback,
      backendInsight: null,
      source: InsightSource.fallback,
      statusMessage: '尚未連線分析服務，先使用本地解讀。',
    );
  }

  Future<void> refresh({MonthlyInsight? seed}) async {
    final fallbackSeed = seed ?? state.fallbackInsight;
    final result = await ref
        .read(l2AnalysisClientProvider)
        .analyzeMonthly(seedInsight: fallbackSeed);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      fallbackInsight: result.usedFallback ? result.insight : fallbackSeed,
      backendInsight: result.usedFallback ? null : result.insight,
      source: result.usedFallback
          ? InsightSource.fallback
          : InsightSource.backend,
      statusMessage: result.reason,
    );
  }
}

enum InsightSource { backend, fallback }

class InsightsState {
  const InsightsState({
    required this.fallbackInsight,
    required this.backendInsight,
    required this.source,
    required this.statusMessage,
  });

  final MonthlyInsight fallbackInsight;
  final MonthlyInsight? backendInsight;
  final InsightSource source;
  final String statusMessage;

  MonthlyInsight get displayInsight => backendInsight ?? fallbackInsight;
  bool get usedFallback => source == InsightSource.fallback;
  String get sourceLabel => usedFallback ? '本地 fallback' : 'FastAPI 後端分析';

  InsightsState copyWith({
    MonthlyInsight? fallbackInsight,
    Object? backendInsight = _keepCurrentBackendInsight,
    InsightSource? source,
    String? statusMessage,
  }) {
    final resolvedBackendInsight =
        identical(backendInsight, _keepCurrentBackendInsight)
        ? this.backendInsight
        : backendInsight as MonthlyInsight?;

    return InsightsState(
      fallbackInsight: fallbackInsight ?? this.fallbackInsight,
      backendInsight: resolvedBackendInsight,
      source: source ?? this.source,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

const _keepCurrentBackendInsight = Object();

const _mockMonthlyInsight = MonthlyInsight(
  month: MonthKey(2026, 4),
  netWorthCurrent: 1462000,
  netWorthDelta: 42000,
  savingsRate: 0.284,
  savingsRateTarget: 0.3,
  budgetCompletion: 0.9,
  budgetHighlights: [
    BudgetRecapItem(label: '固定', completion: 0.94, note: '維持原本節奏即可'),
    BudgetRecapItem(label: '生活', completion: 0.87, note: '可延續目前分配'),
    BudgetRecapItem(label: '彈性', completion: 0.96, note: '下月可預留一點餘裕'),
  ],
  allocationChanges: [
    AllocationChangeItem(
      label: '股票',
      previousWeight: 0.58,
      currentWeight: 0.6,
      targetWeight: 0.6,
    ),
    AllocationChangeItem(
      label: '債券',
      previousWeight: 0.27,
      currentWeight: 0.25,
      targetWeight: 0.25,
    ),
    AllocationChangeItem(
      label: '現金',
      previousWeight: 0.15,
      currentWeight: 0.15,
      targetWeight: 0.15,
    ),
  ],
  aiInterpretation: [
    '淨值延續上月穩定成長，現金流節奏保持一致。',
    '儲蓄率接近目標，可持續維持目前的月度安排。',
    '資產配置已回到目標區間，建議固定頻率追蹤即可。',
  ],
  outlook: '可考慮在下月維持既有定投與預算配置。',
);
