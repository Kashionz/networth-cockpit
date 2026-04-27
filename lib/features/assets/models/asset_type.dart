import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AssetCategory { liquidity, investment, other }

extension AssetCategoryX on AssetCategory {
  String get label => switch (this) {
    AssetCategory.liquidity => '現金與存款',
    AssetCategory.investment => '投資資產',
    AssetCategory.other => '其他資產',
  };
}

enum AssetType {
  cash,
  bankDeposit,
  stockEtf,
  bond,
  crypto,
  retirement,
  vehicle,
  preciousMetal,
}

extension AssetTypeX on AssetType {
  String get label => switch (this) {
    AssetType.cash => '現金',
    AssetType.bankDeposit => '銀行存款',
    AssetType.stockEtf => '股票 / ETF',
    AssetType.bond => '債券',
    AssetType.crypto => '加密資產',
    AssetType.retirement => '退休帳戶',
    AssetType.vehicle => '車輛',
    AssetType.preciousMetal => '黃金 / 貴金屬',
  };

  AssetCategory get category => switch (this) {
    AssetType.cash || AssetType.bankDeposit => AssetCategory.liquidity,
    AssetType.stockEtf ||
    AssetType.bond ||
    AssetType.crypto ||
    AssetType.retirement => AssetCategory.investment,
    AssetType.vehicle || AssetType.preciousMetal => AssetCategory.other,
  };

  IconData get icon => switch (this) {
    AssetType.cash => Icons.payments_outlined,
    AssetType.bankDeposit => Icons.account_balance_outlined,
    AssetType.stockEtf => Icons.show_chart_outlined,
    AssetType.bond => Icons.stacked_line_chart_outlined,
    AssetType.crypto => Icons.currency_bitcoin_outlined,
    AssetType.retirement => Icons.shield_outlined,
    AssetType.vehicle => Icons.directions_car_outlined,
    AssetType.preciousMetal => Icons.workspace_premium_outlined,
  };

  Color get color => switch (this) {
    AssetType.cash || AssetType.bankDeposit => AppColors.assetCash,
    AssetType.stockEtf || AssetType.retirement => AppColors.assetEquity,
    AssetType.bond => AppColors.assetBond,
    AssetType.crypto => AppColors.review,
    AssetType.vehicle || AssetType.preciousMetal => AppColors.near,
  };
}
