import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AssetCategory { equity, bond, cash }

extension AssetCategoryDisplay on AssetCategory {
  String get label => switch (this) {
    AssetCategory.equity => '股票',
    AssetCategory.bond => '債券',
    AssetCategory.cash => '現金',
  };

  Color get color => switch (this) {
    AssetCategory.equity => AppColors.assetEquity,
    AssetCategory.bond => AppColors.assetBond,
    AssetCategory.cash => AppColors.assetCash,
  };
}

class AssetAllocation {
  const AssetAllocation({
    required this.category,
    required this.currentRatio,
    required this.targetRatio,
  });

  final AssetCategory category;
  final double currentRatio;
  final double targetRatio;

  double get driftRatio => currentRatio - targetRatio;

  @override
  bool operator ==(Object other) {
    return other is AssetAllocation &&
        other.category == category &&
        other.currentRatio == currentRatio &&
        other.targetRatio == targetRatio;
  }

  @override
  int get hashCode => Object.hash(category, currentRatio, targetRatio);
}
