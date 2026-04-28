import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/assets/models/asset.dart';
import '../../features/assets/models/asset_type.dart';
import '../../shared/models/money.dart';
import '../services/supabase/supabase_assets_service.dart';
import '../services/supabase/supabase_client_factory.dart';

final assetsRepositoryProvider = Provider<AssetsRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseAssetsService(client: client);

  return AssetsRepositoryImpl(remoteService: remoteService);
});

abstract interface class AssetsRepository {
  List<Asset> get fallbackAssets;

  Future<List<Asset>> fetchAssets();

  Future<List<Asset>> createAsset(
    Asset asset, {
    bool writePriceSnapshot = true,
  });

  Future<List<Asset>> updateAsset(
    Asset asset, {
    bool writePriceSnapshot = true,
  });

  Future<List<Asset>> deleteAsset(String assetId);
}

class AssetsRepositoryImpl implements AssetsRepository {
  AssetsRepositoryImpl({SupabaseAssetsService? remoteService})
    : _remoteService = remoteService,
      _localAssets = List<Asset>.from(_seedAssets);

  final SupabaseAssetsService? _remoteService;
  List<Asset> _localAssets;

  @override
  List<Asset> get fallbackAssets => List<Asset>.unmodifiable(_localAssets);

  @override
  Future<List<Asset>> fetchAssets() async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      return _snapshot();
    }

    try {
      final rows = await remote.fetchAssetsByUserId(userId);
      final parsed = rows.map(_assetFromRow).toList(growable: false);
      _localAssets = _sorted(parsed);
      return _snapshot();
    } catch (error, stackTrace) {
      developer.log(
        'fetchAssets remote call failed',
        name: 'AssetsRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _snapshot();
    }
  }

  @override
  Future<List<Asset>> createAsset(
    Asset asset, {
    bool writePriceSnapshot = true,
  }) {
    return _saveAsset(asset, writePriceSnapshot: writePriceSnapshot);
  }

  @override
  Future<List<Asset>> updateAsset(
    Asset asset, {
    bool writePriceSnapshot = true,
  }) {
    return _saveAsset(asset, writePriceSnapshot: writePriceSnapshot);
  }

  @override
  Future<List<Asset>> deleteAsset(String assetId) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote != null && userId != null) {
      try {
        await remote.deleteHoldingByAssetId(userId: userId, assetId: assetId);
        await remote.deleteAsset(userId: userId, assetId: assetId);
        return fetchAssets();
      } catch (error, stackTrace) {
        developer.log(
          'deleteAsset remote call failed',
          name: 'AssetsRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _localAssets = _localAssets
        .where((asset) => asset.id != assetId)
        .toList(growable: false);
    return _snapshot();
  }

  Future<List<Asset>> _saveAsset(
    Asset asset, {
    required bool writePriceSnapshot,
  }) async {
    final normalized = _normalizeAsset(asset);
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;

    if (remote != null && userId != null) {
      try {
        await _persistRemote(
          remote: remote,
          userId: userId,
          asset: normalized,
          writePriceSnapshot: writePriceSnapshot,
        );
        return fetchAssets();
      } catch (error, stackTrace) {
        developer.log(
          'saveAsset remote call failed',
          name: 'AssetsRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _upsertLocal(normalized);
    return _snapshot();
  }

  Future<void> _persistRemote({
    required SupabaseAssetsService remote,
    required String userId,
    required Asset asset,
    required bool writePriceSnapshot,
  }) async {
    final updatedAt = asset.updatedAt.toUtc().toIso8601String();
    final symbol = _symbolOrFallback(asset);
    await remote.upsertAsset({
      if (_looksLikeUuid(asset.id)) 'id': asset.id,
      'user_id': userId,
      'name': asset.name,
      'symbol': symbol,
      'asset_type': _assetClassForType(asset.type),
      'market': asset.market,
      'currency_code': asset.currency,
      'metadata': {
        'value': asset.value.amount,
        'quantity': asset.quantity,
        'cost_basis': asset.costBasis.amount,
        if (asset.marketQuoteSource != null)
          'market_quote_source': asset.marketQuoteSource,
      },
      'updated_at': updatedAt,
    });

    final unitPrice = _unitPrice(asset);
    final priceDate = asset.updatedAt.toUtc();

    if (writePriceSnapshot) {
      await remote.upsertDailyPrice({
        'asset_id': asset.id,
        'price_date': DateTime.utc(
          priceDate.year,
          priceDate.month,
          priceDate.day,
        ).toIso8601String().substring(0, 10),
        'close': unitPrice,
        'source': 'manual_update',
      });
    }

    // 將估值結果同步到持倉，至少在 repository 層完成回寫流程。
    await remote.upsertHolding({
      'user_id': userId,
      'asset_id': asset.id,
      'quantity': asset.quantity,
      'average_cost': _costBasisAvg(asset),
      'cost_basis_total': asset.costBasis.amount,
      'market_value': asset.value.amount,
      'updated_at': updatedAt,
    });
  }

  void _upsertLocal(Asset asset) {
    _localAssets = _sorted([
      asset,
      for (final current in _localAssets)
        if (current.id != asset.id) current,
    ]);
  }

  List<Asset> _snapshot() => List<Asset>.unmodifiable(_localAssets);

  List<Asset> _sorted(List<Asset> list) {
    final sorted = List<Asset>.from(list)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  Asset _normalizeAsset(Asset asset) {
    final normalizedCurrency = asset.currency.trim().isEmpty
        ? asset.value.currencyCode
        : asset.currency.trim().toUpperCase();
    final normalizedQuantity = asset.quantity <= 0 ? 1 : asset.quantity;
    return asset.copyWith(
      symbol: _normalizeSymbol(asset.symbol),
      quantity: normalizedQuantity,
      costBasis: Money(
        asset.costBasis.amount,
        currencyCode: normalizedCurrency,
      ),
      value: Money(asset.value.amount, currencyCode: normalizedCurrency),
      currency: normalizedCurrency,
      market: _normalizeMarket(asset.market, fallbackType: asset.type),
      updatedAt: asset.updatedAt.toUtc(),
      marketQuoteSource: _normalizeQuoteSource(asset.marketQuoteSource),
    );
  }

  Asset _assetFromRow(Map<String, dynamic> row) {
    final id =
        row['id']?.toString() ??
        'asset-local-${DateTime.now().millisecondsSinceEpoch}';
    final name = row['name']?.toString() ?? '未命名資產';
    final type = _assetTypeFromRaw(
      row['asset_type']?.toString() ?? row['type']?.toString(),
    );
    final metadata = row['metadata'];
    final metadataMap = metadata is Map
        ? Map<String, dynamic>.from(metadata)
        : const <String, dynamic>{};
    final currency =
        (row['currency_code']?.toString() ??
                metadataMap['currency']?.toString() ??
                'TWD')
            .toUpperCase();
    final quantity = _toNum(metadataMap['quantity']) ?? 1;
    final valueAmount = _toNum(metadataMap['value']) ?? 0;
    final costBasisAmount = _toNum(metadataMap['cost_basis']) ?? valueAmount;
    return Asset(
      id: id,
      name: name,
      type: type,
      value: Money(valueAmount, currencyCode: currency),
      symbol: _normalizeSymbol(row['symbol']?.toString()),
      quantity: quantity <= 0 ? 1 : quantity,
      costBasis: Money(costBasisAmount, currencyCode: currency),
      currency: currency,
      market: _normalizeMarket(row['market']?.toString(), fallbackType: type),
      updatedAt: _parseDateTime(row['updated_at']) ?? DateTime.now().toUtc(),
      marketQuoteSource: _normalizeQuoteSource(
        metadataMap['market_quote_source']?.toString(),
      ),
    );
  }

  num _unitPrice(Asset asset) {
    if (asset.quantity <= 0) {
      return asset.value.amount;
    }
    return asset.value.amount / asset.quantity;
  }

  num _costBasisAvg(Asset asset) {
    if (asset.quantity <= 0) {
      return asset.costBasis.amount;
    }
    return asset.costBasis.amount / asset.quantity;
  }

  num? _toNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString());
  }

  DateTime? _parseDateTime(Object? raw) {
    final text = raw?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toUtc();
  }

  String? _normalizeSymbol(String? symbol) {
    final value = symbol?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toUpperCase();
  }

  String? _normalizeQuoteSource(String? source) {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toLowerCase();
  }

  String _normalizeMarket(String? market, {required AssetType fallbackType}) {
    final value = market?.trim().toUpperCase();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return _defaultMarketForType(fallbackType);
  }

  String _symbolOrFallback(Asset asset) {
    final normalized = _normalizeSymbol(asset.symbol);
    if (normalized != null) {
      return normalized;
    }
    final cleaned = asset.id.replaceAll('-', '').toUpperCase();
    final prefix = cleaned.length >= 8 ? cleaned.substring(0, 8) : cleaned;
    return 'ASSET_$prefix';
  }

  bool _looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }
}

String _assetClassForType(AssetType type) => switch (type) {
  AssetType.cash || AssetType.bankDeposit => 'cash',
  AssetType.stockEtf => 'etf',
  AssetType.bond => 'bond',
  AssetType.crypto => 'crypto',
  AssetType.retirement => 'retirement',
  AssetType.vehicle => 'vehicle',
  AssetType.preciousMetal => 'precious_metal',
};

String _defaultMarketForType(AssetType type) => switch (type) {
  AssetType.crypto => 'CRYPTO',
  _ => 'TW',
};

AssetType _assetTypeFromRaw(String? raw) {
  final key = raw?.trim().toLowerCase();
  return switch (key) {
    'cash' => AssetType.cash,
    'bank' || 'bank_deposit' || 'deposit' => AssetType.bankDeposit,
    'stock' || 'etf' || 'stock_etf' => AssetType.stockEtf,
    'bond' => AssetType.bond,
    'crypto' => AssetType.crypto,
    'retirement' => AssetType.retirement,
    'vehicle' => AssetType.vehicle,
    'precious_metal' || 'gold' => AssetType.preciousMetal,
    _ => AssetType.stockEtf,
  };
}

final _seedAssets = [
  Asset(
    id: 'asset-1',
    name: '台幣活存',
    type: AssetType.bankDeposit,
    value: const Money.twd(420000),
    symbol: null,
    quantity: 1,
    costBasis: const Money.twd(420000),
    currency: 'TWD',
    market: 'TW',
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-2',
    name: '緊急預備金',
    type: AssetType.cash,
    value: const Money.twd(90000),
    symbol: null,
    quantity: 1,
    costBasis: const Money.twd(90000),
    currency: 'TWD',
    market: 'TW',
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-3',
    name: '0050 ETF',
    type: AssetType.stockEtf,
    value: const Money.twd(980000),
    symbol: '0050',
    quantity: 6000,
    costBasis: const Money.twd(860000),
    currency: 'TWD',
    market: 'TW',
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-4',
    name: '美國公債 ETF',
    type: AssetType.bond,
    value: const Money.twd(320000),
    symbol: 'TLT',
    quantity: 120,
    costBasis: const Money.twd(300000),
    currency: 'TWD',
    market: 'US',
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-5',
    name: '勞退自提帳戶',
    type: AssetType.retirement,
    value: const Money.twd(230000),
    symbol: null,
    quantity: 1,
    costBasis: const Money.twd(230000),
    currency: 'TWD',
    market: 'TW',
    updatedAt: DateTime(2026, 4, 25),
  ),
  Asset(
    id: 'asset-6',
    name: '通勤車',
    type: AssetType.vehicle,
    value: const Money.twd(180000),
    symbol: null,
    quantity: 1,
    costBasis: const Money.twd(250000),
    currency: 'TWD',
    market: 'TW',
    updatedAt: DateTime(2026, 4, 25),
  ),
];
