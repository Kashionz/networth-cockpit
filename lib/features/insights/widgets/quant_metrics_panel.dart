import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/monthly_insight.dart';

class QuantMetricsPanel extends StatelessWidget {
  const QuantMetricsPanel({required this.metrics, super.key});

  final QuantMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L2 量化指標',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricRow(label: '報酬率', value: metrics.returnRateLabel),
            _MetricRow(label: '波動率', value: metrics.volatilityLabel),
            _MetricRow(label: 'Sharpe', value: metrics.sharpeLabel),
            _MetricRow(label: '最大回撤', value: metrics.maxDrawdownLabel),
            _MetricRow(label: '基準報酬', value: metrics.benchmarkReturnLabel),
            _MetricRow(label: '相對基準', value: metrics.excessReturnLabel),
            if (metrics.stressTests.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                '壓力測試',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final scenario in metrics.stressTests)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '${scenario.name}｜衝擊 ${scenario.shockRateLabel}｜回撤 ${scenario.projectedDrawdownLabel}｜報酬 ${scenario.projectedReturnLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
