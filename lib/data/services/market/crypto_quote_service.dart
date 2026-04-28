import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'market_quote.dart';
import 'market_quote_service.dart';

const _coingeckoEndpointFromEnv = String.fromEnvironment('COINGECKO_BASE_URL');

final cryptoQuoteServiceProvider = Provider<CryptoQuoteService>((ref) {
  final client = ref.watch(marketHttpClientProvider);
  return CryptoQuoteService(httpClient: client);
});

class CryptoQuoteService {
  CryptoQuoteService({String? baseUrl, required http.Client httpClient})
    : baseUrl = _normalize(baseUrl) ?? _normalize(_coingeckoEndpointFromEnv),
      _httpClient = httpClient;

  final String? baseUrl;
  final http.Client _httpClient;

  static const _supportedCoins = {
    'bitcoin': _CoinMeta(symbol: 'BTC', name: 'Bitcoin'),
    'ethereum': _CoinMeta(symbol: 'ETH', name: 'Ethereum'),
  };

  Future<List<MarketQuote>> fetchQuotes({
    Iterable<String> coinIds = const ['bitcoin', 'ethereum'],
  }) async {
    final requested = coinIds
        .map((id) => id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (requested.isEmpty) {
      return const [];
    }

    final asOf = DateTime.now();
    final configuredBaseUrl = baseUrl;
    if (configuredBaseUrl == null) {
      return List<MarketQuote>.unmodifiable(_mockQuotes(requested, asOf: asOf));
    }

    try {
      final uri = Uri.parse('$configuredBaseUrl/api/v3/simple/price').replace(
        queryParameters: {
          'ids': requested.join(','),
          'vs_currencies': 'usd,twd',
          'include_24hr_change': 'true',
          'include_last_updated_at': 'true',
        },
      );
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (!_isSuccess(response.statusCode)) {
        _logFallback(
          'Coingecko quote fetch failed with non-success status.',
          error: 'status=${response.statusCode}',
        );
        return List<MarketQuote>.unmodifiable(
          _mockQuotes(requested, asOf: asOf),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        _logFallback('Coingecko quote parse failed: payload is not a map.');
        return List<MarketQuote>.unmodifiable(
          _mockQuotes(requested, asOf: asOf),
        );
      }

      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      final parsed = <MarketQuote>[];
      for (final id in requested) {
        final row = map[id];
        if (row is! Map) {
          continue;
        }

        final rowMap = row.map((key, value) => MapEntry(key.toString(), value));
        final price = _parseNum(rowMap['twd']) ?? _parseNum(rowMap['usd']);
        if (price == null) {
          continue;
        }
        final change =
            _parseNum(rowMap['twd_24h_change']) ??
            _parseNum(rowMap['usd_24h_change']) ??
            0;
        final updatedEpoch = _parseNum(rowMap['last_updated_at']);
        final updatedAt = updatedEpoch == null
            ? asOf
            : DateTime.fromMillisecondsSinceEpoch(
                updatedEpoch.toInt() * 1000,
                isUtc: true,
              ).toLocal();
        final meta = _supportedCoins[id] ?? _CoinMeta(symbol: id, name: id);

        parsed.add(
          MarketQuote(
            symbol: meta.symbol,
            name: meta.name,
            price: price,
            change: change,
            source: 'coingecko',
            asOf: updatedAt,
          ),
        );
      }

      if (parsed.isNotEmpty && parsed.length == requested.length) {
        return List<MarketQuote>.unmodifiable(parsed);
      }
      _logFallback(
        'Coingecko quote parse failed: missing requested symbols in payload.',
        error: 'requested=${requested.join(",")}, parsed=${parsed.length}',
      );
    } catch (error, stackTrace) {
      _logFallback(
        'Coingecko quote fetch failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return List<MarketQuote>.unmodifiable(_mockQuotes(requested, asOf: asOf));
  }

  List<MarketQuote> _mockQuotes(
    List<String> requested, {
    required DateTime asOf,
  }) {
    return [
      for (final id in requested)
        if (_supportedCoins.containsKey(id))
          MarketQuote(
            symbol: _supportedCoins[id]!.symbol,
            name: _supportedCoins[id]!.name,
            price: switch (id) {
              'bitcoin' => 2145000,
              'ethereum' => 112500,
              _ => 0,
            },
            change: switch (id) {
              'bitcoin' => 1.8,
              'ethereum' => 2.4,
              _ => 0,
            },
            source: 'coingecko-mock',
            asOf: asOf,
          ),
    ];
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  void _logFallback(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'CryptoQuoteService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  num? _parseNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }

    final text = value.toString().trim();
    if (text.isEmpty || text == '--') {
      return null;
    }
    return num.tryParse(text);
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    var trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _CoinMeta {
  const _CoinMeta({required this.symbol, required this.name});

  final String symbol;
  final String name;
}
