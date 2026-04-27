import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/portfolio/models/asset_allocation.dart';
import '../../features/portfolio/models/contribution_direction.dart';
import '../../features/portfolio/models/holding.dart';
import '../../shared/models/money.dart';
import '../mock/mock_portfolio_data.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_portfolio_service.dart';

export '../../features/portfolio/models/asset_allocation.dart';
export '../../features/portfolio/models/contribution_direction.dart';
export '../../features/portfolio/models/holding.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabasePortfolioService(client: client);

  return PortfolioRepositoryImpl(remoteService: remoteService);
});

abstract interface class PortfolioRepository {
  Future<void> refresh();

  List<AssetAllocation> getAllocations();

  List<Holding> getTopHoldings({int limit = 5});

  List<ContributionDirection> getContributionDirections();

  double getTopFiveConcentration();

  double getLargestHoldingConcentration();
}

class MockPortfolioRepository implements PortfolioRepository {
  const MockPortfolioRepository();

  @override
  Future<void> refresh() async {}

  @override
  List<AssetAllocation> getAllocations() => MockPortfolioData.allocations;

  @override
  List<Holding> getTopHoldings({int limit = 5}) {
    return MockPortfolioData.topHoldings.take(limit).toList(growable: false);
  }

  @override
  List<ContributionDirection> getContributionDirections() {
    return MockPortfolioData.contributionDirections;
  }

  @override
  double getTopFiveConcentration() => MockPortfolioData.topFiveConcentration;

  @override
  double getLargestHoldingConcentration() {
    return MockPortfolioData.largestHoldingConcentration;
  }
}

class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl({SupabasePortfolioService? remoteService})
    : _remoteService = remoteService,
      _snapshot = _PortfolioSnapshot.fromMock();

  final SupabasePortfolioService? _remoteService;
  _PortfolioSnapshot _snapshot;

  @override
  Future<void> refresh() async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      return;
    }

    try {
      final responses = await Future.wait<Object?>([
        remote.fetchAssetsByUserId(userId),
        remote.fetchHoldingsByUserId(userId),
        remote.fetchTargetAllocationsByUserId(userId),
        remote.fetchLatestPortfolioSnapshotByUserId(userId),
      ]);

      final assetsRows = responses[0]! as List<Map<String, dynamic>>;
      final holdingsRows = responses[1]! as List<Map<String, dynamic>>;
      final targetRows = responses[2]! as List<Map<String, dynamic>>;
      final snapshotRow = responses[3] as Map<String, dynamic>?;

      final parsed = _buildSnapshot(
        assetsRows: assetsRows,
        holdingsRows: holdingsRows,
        targetRows: targetRows,
        latestSnapshotRow: snapshotRow,
      );

      if (parsed != null) {
        _snapshot = parsed;
      } else {
        developer.log(
          'portfolio remote data is insufficient, keep fallback snapshot',
          name: 'PortfolioRepository',
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'refresh portfolio remote call failed',
        name: 'PortfolioRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  List<AssetAllocation> getAllocations() => _snapshot.allocations;

  @override
  List<Holding> getTopHoldings({int limit = 5}) {
    final safeLimit = limit < 0 ? 0 : limit;
    return _snapshot.topHoldings.take(safeLimit).toList(growable: false);
  }

  @override
  List<ContributionDirection> getContributionDirections() {
    return _snapshot.contributionDirections;
  }

  @override
  double getTopFiveConcentration() => _snapshot.topFiveConcentration;

  @override
  double getLargestHoldingConcentration() {
    return _snapshot.largestHoldingConcentration;
  }

  _PortfolioSnapshot? _buildSnapshot({
    required List<Map<String, dynamic>> assetsRows,
    required List<Map<String, dynamic>> holdingsRows,
    required List<Map<String, dynamic>> targetRows,
    required Map<String, dynamic>? latestSnapshotRow,
  }) {
    final assetsById = <String, Map<String, dynamic>>{
      for (final row in assetsRows)
        if ((row['id']?.toString() ?? '').isNotEmpty) row['id'].toString(): row,
    };

    final positions = _positionsFromHoldings(
      holdingsRows: holdingsRows,
      assetsById: assetsById,
    );
    if (positions.isEmpty) {
      positions.addAll(_positionsFromAssets(assetsRows));
    }
    if (positions.isEmpty) {
      return null;
    }

    final categoryValues = <AssetCategory, double>{
      AssetCategory.equity: 0,
      AssetCategory.bond: 0,
      AssetCategory.cash: 0,
    };
    for (final position in positions) {
      categoryValues[position.category] =
          (categoryValues[position.category] ?? 0) + position.marketValue;
    }

    final snapshotMetadata = _asMap(latestSnapshotRow?['metadata']);
    final snapshotCash = _firstNonNegative([
      latestSnapshotRow?['cash_value'],
      snapshotMetadata['cash_value'],
      snapshotMetadata['cashValue'],
    ]);
    final currentCash = categoryValues[AssetCategory.cash] ?? 0;
    if (snapshotCash != null && snapshotCash > currentCash) {
      categoryValues[AssetCategory.cash] = snapshotCash;
    }

    final totalCurrentValue = categoryValues.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (totalCurrentValue <= 0) {
      return null;
    }

    final targetCategoryValues = _deriveTargetCategoryValues(
      targetRows: targetRows,
      assetsRows: assetsRows,
      assetsById: assetsById,
    );
    final totalTargetValue = targetCategoryValues.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (totalTargetValue <= 0) {
      return null;
    }

    final allocations = [
      for (final category in AssetCategory.values)
        AssetAllocation(
          category: category,
          currentRatio: _ratioToPercent(
            categoryValues[category] ?? 0,
            totalCurrentValue,
          ),
          targetRatio: _ratioToPercent(
            targetCategoryValues[category] ?? 0,
            totalTargetValue,
          ),
        ),
    ];

    final sortedPositions = [...positions]
      ..sort((left, right) => right.marketValue.compareTo(left.marketValue));
    final topHoldings = [
      for (final position in sortedPositions)
        Holding(
          name: position.name,
          marketValue: Money(
            position.marketValue,
            currencyCode: position.currencyCode,
          ),
          weightRatio: _ratioToPercent(position.marketValue, totalCurrentValue),
        ),
    ];

    final topFiveConcentration = topHoldings
        .take(5)
        .fold<double>(0, (sum, holding) => sum + holding.weightRatio);
    final largestConcentration = topHoldings.isEmpty
        ? 0.0
        : topHoldings.first.weightRatio.toDouble();

    return _PortfolioSnapshot(
      allocations: List<AssetAllocation>.unmodifiable(allocations),
      topHoldings: List<Holding>.unmodifiable(topHoldings),
      contributionDirections: List<ContributionDirection>.unmodifiable(
        _deriveContributionDirections(allocations),
      ),
      topFiveConcentration: topFiveConcentration,
      largestHoldingConcentration: largestConcentration,
    );
  }

  List<_PortfolioPosition> _positionsFromHoldings({
    required List<Map<String, dynamic>> holdingsRows,
    required Map<String, Map<String, dynamic>> assetsById,
  }) {
    final positions = <_PortfolioPosition>[];
    for (final row in holdingsRows) {
      final assetId = row['asset_id']?.toString();
      final joinedAsset = _asMap(row['assets']);
      final assetRow = joinedAsset.isNotEmpty
          ? joinedAsset
          : (assetId == null ? const <String, dynamic>{} : assetsById[assetId] ?? const <String, dynamic>{});
      final assetMetadata = _asMap(assetRow['metadata']);
      final holdingMetadata = _asMap(row['metadata']);

      final marketValue = _firstPositive([
        row['market_value'],
        holdingMetadata['market_value'],
        holdingMetadata['value'],
        assetMetadata['market_value'],
        assetMetadata['value'],
      ]);
      if (marketValue == null || marketValue <= 0) {
        continue;
      }

      final category = _categoryFromRaw(
        rawType: assetRow['asset_type']?.toString(),
        metadata: {...assetMetadata, ...holdingMetadata},
      );
      final name = _resolvePositionName(
        assetRow: assetRow,
        metadata: holdingMetadata,
        fallbackAssetId: assetId,
      );
      final currencyCode = _resolveCurrencyCode(
        row: row,
        assetRow: assetRow,
        metadata: holdingMetadata,
      );

      positions.add(
        _PortfolioPosition(
          name: name,
          category: category,
          marketValue: marketValue,
          currencyCode: currencyCode,
        ),
      );
    }
    return positions;
  }

  List<_PortfolioPosition> _positionsFromAssets(
    List<Map<String, dynamic>> assetsRows,
  ) {
    final positions = <_PortfolioPosition>[];
    for (final row in assetsRows) {
      final metadata = _asMap(row['metadata']);
      final marketValue = _firstPositive([
        metadata['market_value'],
        metadata['value'],
        metadata['latest_value'],
      ]);
      if (marketValue == null || marketValue <= 0) {
        continue;
      }
      positions.add(
        _PortfolioPosition(
          name: _resolvePositionName(
            assetRow: row,
            metadata: metadata,
            fallbackAssetId: row['id']?.toString(),
          ),
          category: _categoryFromRaw(
            rawType: row['asset_type']?.toString(),
            metadata: metadata,
          ),
          marketValue: marketValue,
          currencyCode: _resolveCurrencyCode(row: row, assetRow: row, metadata: metadata),
        ),
      );
    }
    return positions;
  }

  Map<AssetCategory, double> _deriveTargetCategoryValues({
    required List<Map<String, dynamic>> targetRows,
    required List<Map<String, dynamic>> assetsRows,
    required Map<String, Map<String, dynamic>> assetsById,
  }) {
    final result = <AssetCategory, double>{
      AssetCategory.equity: 0,
      AssetCategory.bond: 0,
      AssetCategory.cash: 0,
    };

    final today = DateTime.now().toUtc();
    final activeByAsset = <String, _TargetByAsset>{};
    for (final row in targetRows) {
      final assetId = row['asset_id']?.toString();
      if (assetId == null || assetId.isEmpty) {
        continue;
      }
      if (!_isEffectiveAllocation(row, today)) {
        continue;
      }
      final targetPercentage = _toNum(row['target_percentage']);
      if (targetPercentage == null || targetPercentage <= 0) {
        continue;
      }

      final joinedAsset = _asMap(row['assets']);
      final assetRow = joinedAsset.isNotEmpty
          ? joinedAsset
          : assetsById[assetId] ?? const <String, dynamic>{};
      final metadata = {
        ..._asMap(assetRow['metadata']),
        ..._asMap(row['metadata']),
      };
      final category = _categoryFromRaw(
        rawType: assetRow['asset_type']?.toString(),
        metadata: metadata,
      );

      final effectiveFrom =
          _parseDate(row['effective_from']) ??
          _parseDate(row['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final current = activeByAsset[assetId];
      if (current == null || effectiveFrom.isAfter(current.effectiveFrom)) {
        activeByAsset[assetId] = _TargetByAsset(
          category: category,
          targetPercentage: targetPercentage.toDouble(),
          effectiveFrom: effectiveFrom,
        );
      }
    }

    for (final value in activeByAsset.values) {
      result[value.category] = (result[value.category] ?? 0) + value.targetPercentage;
    }

    final totalFromTargetRows = result.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (totalFromTargetRows > 0) {
      return result;
    }

    for (final row in assetsRows) {
      final metadata = _asMap(row['metadata']);
      final fallbackTarget = _firstPositive([
        metadata['target_percentage'],
        metadata['target_ratio'],
        metadata['targetAllocation'],
        metadata['target_allocation'],
      ]);
      if (fallbackTarget == null || fallbackTarget <= 0) {
        continue;
      }
      final category = _categoryFromRaw(
        rawType: row['asset_type']?.toString(),
        metadata: metadata,
      );
      result[category] = (result[category] ?? 0) + fallbackTarget;
    }

    return result;
  }

  List<ContributionDirection> _deriveContributionDirections(
    List<AssetAllocation> allocations,
  ) {
    final deficits = <AssetCategory, double>{
      for (final allocation in allocations)
        allocation.category: math.max(
          0,
          allocation.targetRatio - allocation.currentRatio,
        ),
    };
    final totalDeficit = deficits.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    if (totalDeficit > 0) {
      return [
        for (final allocation in allocations)
          ContributionDirection(
            category: allocation.category,
            ratio: _ratioToPercent(
              deficits[allocation.category] ?? 0,
              totalDeficit,
            ),
            note: _neutralDirectionNote(allocation.driftRatio),
          ),
      ];
    }

    final targetTotal = allocations.fold<double>(
      0,
      (sum, allocation) => sum + allocation.targetRatio,
    );
    if (targetTotal <= 0) {
      final evenRatio = 100 / allocations.length;
      return [
        for (final allocation in allocations)
          ContributionDirection(
            category: allocation.category,
            ratio: evenRatio,
            note: _neutralDirectionNote(allocation.driftRatio),
          ),
      ];
    }

    return [
      for (final allocation in allocations)
        ContributionDirection(
          category: allocation.category,
          ratio: _ratioToPercent(allocation.targetRatio, targetTotal),
          note: _neutralDirectionNote(allocation.driftRatio),
        ),
    ];
  }

  String _neutralDirectionNote(double driftRatio) {
    if (driftRatio <= -2.5) {
      return '目前低於目標，可用新投入資金逐步調整。';
    }
    if (driftRatio >= 2.5) {
      return '目前高於目標，新投入可相對放緩。';
    }
    return '目前接近目標比例，可維持既有投入節奏。';
  }

  String _resolvePositionName({
    required Map<String, dynamic> assetRow,
    required Map<String, dynamic> metadata,
    required String? fallbackAssetId,
  }) {
    final candidate =
        metadata['display_name'] ??
        metadata['name'] ??
        assetRow['name'] ??
        assetRow['symbol'];
    final text = candidate?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
    if (fallbackAssetId != null && fallbackAssetId.isNotEmpty) {
      return '資產 $fallbackAssetId';
    }
    return '未命名持倉';
  }

  String _resolveCurrencyCode({
    required Map<String, dynamic> row,
    required Map<String, dynamic> assetRow,
    required Map<String, dynamic> metadata,
  }) {
    final candidate =
        metadata['currency'] ??
        metadata['currency_code'] ??
        row['currency_code'] ??
        assetRow['currency_code'];
    final text = candidate?.toString().trim().toUpperCase();
    if (text == null || text.isEmpty) {
      return 'TWD';
    }
    return text;
  }

  AssetCategory _categoryFromRaw({
    required String? rawType,
    required Map<String, dynamic> metadata,
  }) {
    final metadataHint =
        metadata['allocation_category'] ??
        metadata['category'] ??
        metadata['asset_bucket'] ??
        metadata['bucket'];
    final metadataKey = metadataHint?.toString().trim().toLowerCase();
    if (metadataKey != null && metadataKey.isNotEmpty) {
      if (metadataKey.contains('bond') || metadataKey.contains('債')) {
        return AssetCategory.bond;
      }
      if (metadataKey.contains('cash') ||
          metadataKey.contains('現金') ||
          metadataKey.contains('deposit') ||
          metadataKey.contains('bank')) {
        return AssetCategory.cash;
      }
      return AssetCategory.equity;
    }

    final normalized = rawType?.trim().toLowerCase();
    return switch (normalized) {
      'bond' => AssetCategory.bond,
      'cash' || 'bank' || 'bank_deposit' || 'deposit' => AssetCategory.cash,
      _ => AssetCategory.equity,
    };
  }

  bool _isEffectiveAllocation(Map<String, dynamic> row, DateTime todayUtc) {
    final fromDate = _parseDate(row['effective_from']);
    final toDate = _parseDate(row['effective_to']);
    final day = DateTime.utc(todayUtc.year, todayUtc.month, todayUtc.day);
    if (fromDate != null && day.isBefore(fromDate)) {
      return false;
    }
    if (toDate != null && day.isAfter(toDate)) {
      return false;
    }
    return true;
  }

  double _ratioToPercent(double numerator, double denominator) {
    if (denominator <= 0) {
      return 0;
    }
    final ratio = (numerator / denominator) * 100;
    return ratio.isFinite ? ratio : 0;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  DateTime? _parseDate(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
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

  double? _firstPositive(List<Object?> values) {
    for (final value in values) {
      final numValue = _toNum(value);
      if (numValue != null && numValue > 0) {
        return numValue.toDouble();
      }
    }
    return null;
  }

  double? _firstNonNegative(List<Object?> values) {
    for (final value in values) {
      final numValue = _toNum(value);
      if (numValue != null && numValue >= 0) {
        return numValue.toDouble();
      }
    }
    return null;
  }
}

class _PortfolioSnapshot {
  const _PortfolioSnapshot({
    required this.allocations,
    required this.topHoldings,
    required this.contributionDirections,
    required this.topFiveConcentration,
    required this.largestHoldingConcentration,
  });

  factory _PortfolioSnapshot.fromMock() {
    return const _PortfolioSnapshot(
      allocations: MockPortfolioData.allocations,
      topHoldings: MockPortfolioData.topHoldings,
      contributionDirections: MockPortfolioData.contributionDirections,
      topFiveConcentration: MockPortfolioData.topFiveConcentration,
      largestHoldingConcentration: MockPortfolioData.largestHoldingConcentration,
    );
  }

  final List<AssetAllocation> allocations;
  final List<Holding> topHoldings;
  final List<ContributionDirection> contributionDirections;
  final double topFiveConcentration;
  final double largestHoldingConcentration;
}

class _PortfolioPosition {
  const _PortfolioPosition({
    required this.name,
    required this.category,
    required this.marketValue,
    required this.currencyCode,
  });

  final String name;
  final AssetCategory category;
  final double marketValue;
  final String currencyCode;
}

class _TargetByAsset {
  const _TargetByAsset({
    required this.category,
    required this.targetPercentage,
    required this.effectiveFrom,
  });

  final AssetCategory category;
  final double targetPercentage;
  final DateTime effectiveFrom;
}
