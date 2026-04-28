import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/portfolio_repository.dart';
import 'package:networth_cockpit/data/services/supabase/supabase_portfolio_service.dart';

void main() {
  group('PortfolioRepository correlation matrix', () {
    test('derives matrix from daily prices for top holdings', () async {
      final repository = PortfolioRepositoryImpl(
        remoteService: _FakePortfolioRemoteService(
          assetsRows: [
            {
              'id': 'asset-a',
              'asset_type': 'equity',
              'name': '測試持股 A',
              'currency_code': 'TWD',
              'metadata': {},
            },
            {
              'id': 'asset-b',
              'asset_type': 'equity',
              'name': '測試持股 B',
              'currency_code': 'TWD',
              'metadata': {},
            },
            {
              'id': 'asset-c',
              'asset_type': 'bond',
              'name': '測試持股 C',
              'currency_code': 'TWD',
              'metadata': {},
            },
          ],
          holdingsRows: [
            {
              'asset_id': 'asset-a',
              'market_value': 300000,
              'metadata': {},
              'assets': {
                'id': 'asset-a',
                'name': '測試持股 A',
                'asset_type': 'equity',
                'currency_code': 'TWD',
                'metadata': {},
              },
            },
            {
              'asset_id': 'asset-b',
              'market_value': 250000,
              'metadata': {},
              'assets': {
                'id': 'asset-b',
                'name': '測試持股 B',
                'asset_type': 'equity',
                'currency_code': 'TWD',
                'metadata': {},
              },
            },
            {
              'asset_id': 'asset-c',
              'market_value': 200000,
              'metadata': {},
              'assets': {
                'id': 'asset-c',
                'name': '測試持股 C',
                'asset_type': 'bond',
                'currency_code': 'TWD',
                'metadata': {},
              },
            },
          ],
          targetRows: [
            {'asset_id': 'asset-a', 'target_percentage': 40, 'metadata': {}},
            {'asset_id': 'asset-b', 'target_percentage': 35, 'metadata': {}},
            {'asset_id': 'asset-c', 'target_percentage': 25, 'metadata': {}},
          ],
          latestSnapshotRow: null,
          priceRows: [
            for (final item in _series('asset-a', [
              100,
              102,
              104,
              106,
              108,
              110,
            ]))
              item,
            for (final item in _series('asset-b', [
              200,
              204,
              208,
              212,
              216,
              220,
            ]))
              item,
            for (final item in _series('asset-c', [100, 99, 98, 97, 96, 95]))
              item,
          ],
        ),
      );

      await repository.refresh();

      final matrix = repository.getCorrelationMatrix();
      final risks = repository.getHighCorrelationRisks();

      expect(matrix.holdingNames, hasLength(3));
      expect(matrix.valueAt(0, 0), 1);
      expect(matrix.valueAt(0, 1), isNotNull);
      expect(matrix.valueAt(0, 1)!, greaterThan(0.99));
      expect(risks, isNotEmpty);
      expect(
        risks.any(
          (risk) =>
              risk.leftHoldingName == '測試持股 A' &&
              risk.rightHoldingName == '測試持股 B' &&
              risk.coefficient > 0.8,
        ),
        isTrue,
      );
    });
  });
}

List<Map<String, dynamic>> _series(String assetId, List<num> closes) {
  final rows = <Map<String, dynamic>>[];
  for (var index = 0; index < closes.length; index++) {
    rows.add({
      'asset_id': assetId,
      'price_date': '2026-04-${(index + 1).toString().padLeft(2, '0')}',
      'close': closes[index],
      'adjusted_close': closes[index],
    });
  }
  return rows;
}

class _FakePortfolioRemoteService implements PortfolioRemoteService {
  const _FakePortfolioRemoteService({
    required this.assetsRows,
    required this.holdingsRows,
    required this.targetRows,
    required this.latestSnapshotRow,
    required this.priceRows,
  });

  final List<Map<String, dynamic>> assetsRows;
  final List<Map<String, dynamic>> holdingsRows;
  final List<Map<String, dynamic>> targetRows;
  final Map<String, dynamic>? latestSnapshotRow;
  final List<Map<String, dynamic>> priceRows;

  @override
  String? get currentUserId => 'user-test';

  @override
  Future<List<Map<String, dynamic>>> fetchAssetsByUserId(String userId) async {
    return assetsRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchHoldingsByUserId(
    String userId,
  ) async {
    return holdingsRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTargetAllocationsByUserId(
    String userId,
  ) async {
    return targetRows;
  }

  @override
  Future<Map<String, dynamic>?> fetchLatestPortfolioSnapshotByUserId(
    String userId,
  ) async {
    return latestSnapshotRow;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDailyPricesByAssetIds({
    required List<String> assetIds,
    int lookbackDays = 120,
  }) async {
    return priceRows
        .where((row) => assetIds.contains(row['asset_id']?.toString()))
        .toList(growable: false);
  }
}
