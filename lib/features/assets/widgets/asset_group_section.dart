import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../models/asset.dart';
import 'asset_list_item.dart';

class AssetGroupSection extends StatelessWidget {
  const AssetGroupSection({
    super.key,
    required this.title,
    required this.assets,
    required this.portfolioTotal,
    required this.onAdjustValue,
    required this.onDelete,
  });

  final String title;
  final List<Asset> assets;
  final num portfolioTotal;
  final ValueChanged<Asset> onAdjustValue;
  final ValueChanged<Asset> onDelete;

  @override
  Widget build(BuildContext context) {
    final groupTotal = assets.fold<num>(
      0,
      (sum, item) => sum + item.value.amount,
    );
    final groupRatio = portfolioTotal == 0 ? 0 : groupTotal / portfolioTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyDisplay(
                  amount: groupTotal,
                  size: 16,
                  weight: FontWeight.w700,
                ),
                Text(
                  '佔比 ${(groupRatio * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in assets.indexed) ...[
          AssetListItem(
            asset: entry.$2,
            ratio: portfolioTotal == 0
                ? 0
                : entry.$2.value.amount / portfolioTotal,
            onAdjustValue: () => onAdjustValue(entry.$2),
            onDelete: () => onDelete(entry.$2),
          ),
          if (entry.$1 != assets.length - 1)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}
