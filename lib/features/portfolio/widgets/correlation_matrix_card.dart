import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/correlation_matrix.dart';

class CorrelationMatrixCard extends StatelessWidget {
  const CorrelationMatrixCard({
    required this.matrix,
    required this.highCorrelationRisks,
    super.key,
  });

  final CorrelationMatrix matrix;
  final List<HighCorrelationRisk> highCorrelationRisks;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '相關性矩陣（Top 持股）',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '依最近可用日報酬估算，數值越接近 1 代表同向程度越高。',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (matrix.size < 2)
              Text(
                '目前資料不足，待累積更多價格資料後即可顯示矩陣。',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              _MatrixTable(matrix: matrix),
            const SizedBox(height: AppSpacing.md),
            Text(
              '高同向風險提示（>0.8）',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (highCorrelationRisks.isEmpty)
              Text(
                '目前未觀察到明顯高同向組合，可維持既有檢視頻率。',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 0,
                ),
              )
            else
              for (final risk in highCorrelationRisks)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Text(
                    '• ${risk.leftHoldingName} × ${risk.rightHoldingName}：${risk.coefficient.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({required this.matrix});

  final CorrelationMatrix matrix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(84),
        border: TableBorder.all(color: colorScheme.outlineVariant),
        children: [
          TableRow(
            children: [
              const _HeaderCell(label: ''),
              for (final name in matrix.holdingNames) _HeaderCell(label: name),
            ],
          ),
          for (var row = 0; row < matrix.size; row++)
            TableRow(
              children: [
                _HeaderCell(label: matrix.holdingNames[row]),
                for (var column = 0; column < matrix.size; column++)
                  _ValueCell(
                    value: matrix.valueAt(row, column),
                    diagonal: row == column,
                    textTheme: textTheme,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: SizedBox(
        width: 84,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.value,
    required this.diagonal,
    required this.textTheme,
  });

  final double? value;
  final bool diagonal;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasStrongCoMovement = !diagonal && value != null && value! > 0.8;

    return Container(
      alignment: Alignment.center,
      color: diagonal
          ? colorScheme.surfaceContainerHighest
          : hasStrongCoMovement
          ? colorScheme.tertiaryContainer.withValues(alpha: 0.45)
          : null,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        value == null ? '—' : value!.toStringAsFixed(2),
        style: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: diagonal ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
