import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/money.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

final assetsControllerProvider =
    NotifierProvider<AssetsController, List<Asset>>(AssetsController.new);

class AssetsController extends Notifier<List<Asset>> {
  int _idSeed = _seedAssets.length + 1;

  @override
  List<Asset> build() {
    return List<Asset>.unmodifiable(_seedAssets);
  }

  void addAsset({
    required String name,
    required AssetType type,
    required Money value,
  }) {
    final next = [
      Asset(
        id: 'asset-${_idSeed++}',
        name: name,
        type: type,
        value: value,
        updatedAt: DateTime.now(),
      ),
      ...state,
    ];

    state = List<Asset>.unmodifiable(next);
  }

  void updateAsset(Asset updated) {
    state = List<Asset>.unmodifiable([
      for (final asset in state)
        if (asset.id == updated.id) updated else asset,
    ]);
  }

  void quickIncreaseValue(String assetId, {num delta = 1000}) {
    state = List<Asset>.unmodifiable([
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            value: Money.twd(asset.value.amount + delta),
            updatedAt: DateTime.now(),
          )
        else
          asset,
    ]);
  }

  void deleteAsset(String assetId) {
    state = List<Asset>.unmodifiable(
      state.where((asset) => asset.id != assetId),
    );
  }
}

final _seedAssets = [
  Asset(
    id: 'asset-1',
    name: '台幣活存',
    type: AssetType.bankDeposit,
    value: const Money.twd(420000),
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-2',
    name: '緊急預備金',
    type: AssetType.cash,
    value: const Money.twd(90000),
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-3',
    name: '0050 ETF',
    type: AssetType.stockEtf,
    value: const Money.twd(980000),
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-4',
    name: '美國公債 ETF',
    type: AssetType.bond,
    value: const Money.twd(320000),
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-5',
    name: '勞退自提帳戶',
    type: AssetType.retirement,
    value: const Money.twd(230000),
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-6',
    name: '通勤車',
    type: AssetType.vehicle,
    value: const Money.twd(180000),
    updatedAt: DateTime(2026, 4, 25),
  ),
];
