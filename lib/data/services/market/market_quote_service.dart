import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'market_quote.dart';

const _twseEndpointFromEnv = String.fromEnvironment('TWSE_OPENAPI_ENDPOINT');
const _tpexEndpointFromEnv = String.fromEnvironment('TPEX_OPENAPI_ENDPOINT');
const _defaultTwseEndpoint =
    'https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL';
const _defaultTpexEndpoint =
    'https://www.tpex.org.tw/openapi/v1/tpex_mainboard_quotes';

final marketHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final marketQuoteServiceProvider = Provider<MarketQuoteService>((ref) {
  final client = ref.watch(marketHttpClientProvider);
  return MarketQuoteService(httpClient: client);
});

class MarketQuoteService {
  MarketQuoteService({
    String? twseEndpoint,
    String? tpexEndpoint,
    required http.Client httpClient,
  }) : twseEndpoint =
           _normalize(twseEndpoint) ??
           _normalize(_twseEndpointFromEnv) ??
           _defaultTwseEndpoint,
       tpexEndpoint =
           _normalize(tpexEndpoint) ??
           _normalize(_tpexEndpointFromEnv) ??
           _defaultTpexEndpoint,
       _httpClient = httpClient;

  final String twseEndpoint;
  final String tpexEndpoint;
  final http.Client _httpClient;

  Future<List<MarketQuote>> fetchQuotes({Iterable<String>? symbols}) async {
    final normalizedSymbols = symbols
        ?.map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toSet();

    final results = await Future.wait([_fetchTwseQuotes(), _fetchTpexQuotes()]);

    final merged = [...results[0], ...results[1]];
    final visible = normalizedSymbols == null || normalizedSymbols.isEmpty
        ? merged
        : merged.where((quote) => normalizedSymbols.contains(quote.symbol));

    if (visible.isNotEmpty) {
      return List<MarketQuote>.unmodifiable(visible);
    }

    if (normalizedSymbols != null && normalizedSymbols.isNotEmpty) {
      return List<MarketQuote>.unmodifiable(
        _mockQuotes().where(
          (quote) => normalizedSymbols.contains(quote.symbol),
        ),
      );
    }

    return List<MarketQuote>.unmodifiable(_mockQuotes());
  }

  Future<List<MarketQuote>> _fetchTwseQuotes() async {
    final now = DateTime.now();
    try {
      final response = await _httpClient
          .get(Uri.parse(twseEndpoint))
          .timeout(const Duration(seconds: 8));
      if (!_isSuccess(response.statusCode)) {
        return _mockTwseQuotes(asOf: now);
      }

      final decoded = jsonDecode(response.body);
      final rows = _toRows(decoded);
      final parsed = rows
          .map((row) => _parseTwseRow(row))
          .whereType<MarketQuote>()
          .toList(growable: false);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    } catch (error, stackTrace) {
      developer.log(
        'TWSE quote fetch failed.',
        name: 'MarketQuoteService',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return _mockTwseQuotes(asOf: now);
  }

  Future<List<MarketQuote>> _fetchTpexQuotes() async {
    final now = DateTime.now();
    try {
      final response = await _httpClient
          .get(Uri.parse(tpexEndpoint))
          .timeout(const Duration(seconds: 8));
      if (!_isSuccess(response.statusCode)) {
        return _mockTpexQuotes(asOf: now);
      }

      final decoded = jsonDecode(response.body);
      final rows = _toRows(decoded);
      final parsed = rows
          .map((row) => _parseTpexRow(row))
          .whereType<MarketQuote>()
          .toList(growable: false);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    } catch (error, stackTrace) {
      developer.log(
        'TPEx quote fetch failed.',
        name: 'MarketQuoteService',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return _mockTpexQuotes(asOf: now);
  }

  MarketQuote? _parseTwseRow(Map<String, dynamic> row) {
    final symbol = _pickString(row, const [
      'Code',
      '證券代號',
      '股票代號',
      'stockNo',
      'Symbol',
    ]);
    if (symbol == null) {
      return null;
    }

    final name = _pickString(row, const ['Name', '證券名稱', '公司名稱']) ?? symbol;
    final price = _pickNum(row, const ['ClosingPrice', '收盤價', '成交價', 'Price']);
    if (price == null) {
      return null;
    }
    final change =
        _pickNum(row, const ['Change', '漲跌價差', '漲跌', 'PriceChange']) ?? 0;

    return MarketQuote(
      symbol: symbol.toUpperCase(),
      name: name,
      price: price,
      change: change,
      source: 'twse',
      asOf: _pickDate(row, const ['Date', '資料日期']) ?? DateTime.now(),
    );
  }

  MarketQuote? _parseTpexRow(Map<String, dynamic> row) {
    final symbol = _pickString(row, const [
      'SecuritiesCompanyCode',
      '公司代號',
      '股票代號',
      '證券代號',
      'Code',
    ]);
    if (symbol == null) {
      return null;
    }

    final name =
        _pickString(row, const ['CompanyName', '公司名稱', '證券名稱']) ?? symbol;
    final price = _pickNum(row, const ['Close', '收盤價', '成交價', 'Price']);
    if (price == null) {
      return null;
    }
    final change =
        _pickNum(row, const ['Change', '漲跌價差', '漲跌', 'PriceChange']) ?? 0;

    return MarketQuote(
      symbol: symbol.toUpperCase(),
      name: name,
      price: price,
      change: change,
      source: 'tpex',
      asOf: _pickDate(row, const ['Date', '資料日期']) ?? DateTime.now(),
    );
  }

  List<MarketQuote> _mockQuotes() {
    final now = DateTime.now();
    return [..._mockTwseQuotes(asOf: now), ..._mockTpexQuotes(asOf: now)];
  }

  List<MarketQuote> _mockTwseQuotes({required DateTime asOf}) {
    return [
      MarketQuote(
        symbol: '2330',
        name: '台積電',
        price: 930,
        change: 6,
        source: 'twse-mock',
        asOf: asOf,
      ),
      MarketQuote(
        symbol: '0050',
        name: '元大台灣50',
        price: 170.4,
        change: 1.1,
        source: 'twse-mock',
        asOf: asOf,
      ),
    ];
  }

  List<MarketQuote> _mockTpexQuotes({required DateTime asOf}) {
    return [
      MarketQuote(
        symbol: '8069',
        name: '元太',
        price: 236.5,
        change: -2.5,
        source: 'tpex-mock',
        asOf: asOf,
      ),
      MarketQuote(
        symbol: '8446',
        name: '華研',
        price: 112,
        change: 0.3,
        source: 'tpex-mock',
        asOf: asOf,
      ),
    ];
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  List<Map<String, dynamic>> _toRows(Object? decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (row) => row.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    }

    if (decoded is Map) {
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      final data = map['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (row) => row.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList(growable: false);
      }
    }

    return const [];
  }

  String? _pickString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text != '--') {
        return text;
      }
    }
    return null;
  }

  num? _pickNum(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) {
        continue;
      }

      final parsed = _parseNum(value);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  DateTime? _pickDate(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  num? _parseNum(Object value) {
    if (value is num) {
      return value;
    }

    final cleaned = value
        .toString()
        .trim()
        .replaceAll(',', '')
        .replaceAll('%', '')
        .replaceAll('X', '')
        .replaceAll('+', '')
        .replaceAll('−', '-');
    if (cleaned.isEmpty || cleaned == '--') {
      return null;
    }

    return num.tryParse(cleaned);
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
