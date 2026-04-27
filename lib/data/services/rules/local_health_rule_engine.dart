import 'health_models.dart';

class LocalHealthRuleEngine {
  const LocalHealthRuleEngine();

  HealthRuleEvaluation evaluate(
    HealthDashboardMetrics metrics, {
    String? reason,
  }) {
    final hints = <HealthHint>[];

    if (metrics.savingsRatePct < 10) {
      hints.add(
        const HealthHint(
          id: 'savings-rate',
          title: '儲蓄率可以再往上調整',
          detail: '可先從固定提高 1% 開始，逐步接近每月 10% 以上。',
          level: HealthHintLevel.watch,
        ),
      );
    }

    if (metrics.liquidityMonths < 3) {
      hints.add(
        const HealthHint(
          id: 'liquidity',
          title: '預備金月數可再補強',
          detail: '建議分期補到 3 至 6 個月生活費，保留調整彈性。',
          level: HealthHintLevel.watch,
        ),
      );
    }

    if (metrics.debtToIncomePct > 40) {
      hints.add(
        const HealthHint(
          id: 'debt-ratio',
          title: '負債占比值得持續優化',
          detail: '可優先整理高利率帳戶，循序降低每月固定負擔。',
          level: HealthHintLevel.watch,
        ),
      );
    }

    if (metrics.netWorthChangePct < 0) {
      hints.add(
        const HealthHint(
          id: 'net-worth-volatility',
          title: '本月淨值有波動',
          detail: '可搭配收支與資產配置一起檢視，逐步拉回目標節奏。',
          level: HealthHintLevel.info,
        ),
      );
    }

    if (hints.isEmpty) {
      hints.add(
        const HealthHint(
          id: 'stable',
          title: '整體指標維持穩定',
          detail: '可持續追蹤每月變化，維持目前的資產配置節奏。',
          level: HealthHintLevel.info,
        ),
      );
    }

    return HealthRuleEvaluation(
      summary: '已使用本地規則完成健康檢視。',
      hints: List<HealthHint>.unmodifiable(hints),
      source: HealthRuleSource.localFallback,
      usedFallback: true,
      note: reason,
    );
  }
}
