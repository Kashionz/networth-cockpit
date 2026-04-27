import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/data_display/money_display.dart';
import '../controllers/assets_controller.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../widgets/asset_group_section.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsControllerProvider);
    final controller = ref.read(assetsControllerProvider.notifier);
    final totalValue = assets.fold<num>(
      0,
      (sum, item) => sum + item.value.amount,
    );
    final groupedAssets = _groupAssetsByCategory(assets);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                '資產總覽',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '依類別查看估值與佔比，調整時可先用模擬資料快速整理。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '目前資產總值',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            MoneyDisplay(
                              amount: totalValue,
                              size: 22,
                              weight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.go(RoutePaths.assetsAdd),
                        icon: const Icon(Icons.add),
                        label: const Text('新增資產'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (assets.isEmpty)
                const _EmptyAssetsState()
              else
                for (final entry in groupedAssets.indexed) ...[
                  AssetGroupSection(
                    title: entry.$2.$1.label,
                    assets: entry.$2.$2,
                    portfolioTotal: totalValue,
                    onAdjustValue: (asset) =>
                        controller.quickIncreaseValue(asset.id),
                    onDelete: (asset) => controller.deleteAsset(asset.id),
                  ),
                  if (entry.$1 != groupedAssets.length - 1)
                    const SizedBox(height: AppSpacing.lg),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

List<(AssetCategory, List<Asset>)> _groupAssetsByCategory(List<Asset> assets) {
  final grouped = <AssetCategory, List<Asset>>{
    for (final category in AssetCategory.values) category: [],
  };

  for (final asset in assets) {
    grouped[asset.type.category]!.add(asset);
  }

  return [
    for (final category in AssetCategory.values)
      if (grouped[category]!.isNotEmpty) (category, grouped[category]!),
  ];
}

class _EmptyAssetsState extends StatelessWidget {
  const _EmptyAssetsState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '目前還沒有資產資料，可以先新增一筆開始。',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
