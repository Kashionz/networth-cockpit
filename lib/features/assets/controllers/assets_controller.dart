import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/assets_repository.dart';
import '../../../shared/models/money.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

final assetsControllerProvider =
    NotifierProvider<AssetsController, List<Asset>>(AssetsController.new);

class AssetsController extends Notifier<List<Asset>> {
  late final AssetsRepository _repository;

  @override
  List<Asset> build() {
    _repository = ref.read(assetsRepositoryProvider);
    Future<void>.microtask(reload);
    return List<Asset>.unmodifiable(_repository.fallbackAssets);
  }

  Future<void> reload() async {
    final loaded = await _repository.fetchAssets();
    if (!ref.mounted) {
      return;
    }
    state = List<Asset>.unmodifiable(loaded);
  }

  Future<void> addAsset({
    required String name,
    required AssetType type,
    required Money value,
    String? symbol,
    num? quantity,
    Money? costBasis,
    String? currency,
    String? market,
    String? marketQuoteSource,
  }) async {
    final normalizedCurrency = (currency ?? value.currencyCode)
        .trim()
        .toUpperCase();
    final normalizedQuantity = quantity == null || quantity <= 0 ? 1 : quantity;
    final created = Asset(
      id: 'asset-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: type,
      value: Money(value.amount, currencyCode: normalizedCurrency),
      symbol: symbol,
      quantity: normalizedQuantity,
      costBasis:
          costBasis ?? Money(value.amount, currencyCode: normalizedCurrency),
      currency: normalizedCurrency,
      market: (market == null || market.trim().isEmpty)
          ? _defaultMarketForType(type)
          : market.trim().toUpperCase(),
      updatedAt: DateTime.now().toUtc(),
      marketQuoteSource: marketQuoteSource,
    );

    state = List<Asset>.unmodifiable([created, ...state]);
    final next = await _repository.createAsset(created);
    if (!ref.mounted) {
      return;
    }
    state = List<Asset>.unmodifiable(next);
  }

  Future<void> updateAsset(Asset updated) async {
    final refreshed = updated.copyWith(updatedAt: DateTime.now().toUtc());
    state = List<Asset>.unmodifiable([
      for (final asset in state)
        if (asset.id == refreshed.id) refreshed else asset,
    ]);
    final next = await _repository.updateAsset(refreshed);
    if (!ref.mounted) {
      return;
    }
    state = List<Asset>.unmodifiable(next);
  }

  Future<void> quickIncreaseValue(String assetId, {num delta = 1000}) async {
    Asset? target;
    for (final asset in state) {
      if (asset.id == assetId) {
        target = asset;
        break;
      }
    }
    if (target == null) {
      return;
    }

    await updateAsset(
      target.copyWith(
        value: Money(
          target.value.amount + delta,
          currencyCode: target.currency,
        ),
      ),
    );
  }

  Future<void> deleteAsset(String assetId) async {
    state = List<Asset>.unmodifiable(
      state.where((asset) => asset.id != assetId),
    );
    final next = await _repository.deleteAsset(assetId);
    if (!ref.mounted) {
      return;
    }
    state = List<Asset>.unmodifiable(next);
  }
}

String _defaultMarketForType(AssetType type) => switch (type) {
  AssetType.crypto => 'CRYPTO',
  _ => 'TW',
};
