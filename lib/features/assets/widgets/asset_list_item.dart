import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

class AssetListItem extends StatelessWidget {
  const AssetListItem({
    super.key,
    required this.asset,
    required this.ratio,
    this.onAdjustValue,
    this.onDelete,
  });

  final Asset asset;
  final double ratio;
  final VoidCallback? onAdjustValue;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final showMockPlaceholder =
        asset.type == AssetType.crypto &&
        _isMockSource(asset.marketQuoteSource);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: asset.type.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(asset.type.icon, size: 18, color: asset.type.color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    asset.type.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showMockPlaceholder)
                  Text(
                    '--',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  MoneyDisplay(
                    amount: asset.value,
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _ratioLabel(ratio),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: '調整估值',
              onPressed: onAdjustValue,
              icon: const Icon(Icons.add_chart_outlined),
            ),
            IconButton(
              tooltip: '移除資產',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

String _ratioLabel(double ratio) => '${(ratio * 100).toStringAsFixed(1)}%';

bool _isMockSource(String? source) =>
    source != null && source.trim().toLowerCase().endsWith('-mock');
