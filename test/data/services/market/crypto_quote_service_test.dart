import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/market/crypto_quote_service.dart';

void main() {
  test('crypto quote service parses real quotes on HTTP 200', () async {
    Uri? requestedUri;
    final service = CryptoQuoteService(
      baseUrl: 'https://example.com',
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'bitcoin': {
              'usd': 67500,
              'twd': 2200000,
              'twd_24h_change': 1.5,
              'last_updated_at': 1710000000,
            },
            'ethereum': {
              'usd': 3300,
              'twd': 108000,
              'twd_24h_change': -0.4,
              'last_updated_at': 1710003600,
            },
          }),
          200,
        );
      }),
    );

    final quotes = await service.fetchQuotes();

    expect(requestedUri, isNotNull);
    expect(requestedUri!.path, '/api/v3/simple/price');
    expect(requestedUri!.queryParameters['ids'], 'bitcoin,ethereum');
    expect(requestedUri!.queryParameters['vs_currencies'], 'usd,twd');

    final bySymbol = {for (final quote in quotes) quote.symbol: quote};
    expect(bySymbol.keys, containsAll(const ['BTC', 'ETH']));
    expect(bySymbol['BTC']?.price, 2200000);
    expect(bySymbol['BTC']?.change, 1.5);
    expect(bySymbol['BTC']?.source, 'coingecko');
    expect(bySymbol['ETH']?.price, 108000);
    expect(bySymbol['ETH']?.change, -0.4);
    expect(bySymbol['ETH']?.source, 'coingecko');
  });

  test('crypto quote service falls back to mock when HTTP fails', () async {
    final service = CryptoQuoteService(
      baseUrl: 'https://example.com',
      httpClient: MockClient((_) async => http.Response('oops', 500)),
    );

    final quotes = await service.fetchQuotes(coinIds: const ['bitcoin']);

    expect(quotes, hasLength(1));
    expect(quotes.single.symbol, 'BTC');
    expect(quotes.single.source, 'coingecko-mock');
  });

  test(
    'crypto quote service uses mock directly when baseUrl is null',
    () async {
      var requestCount = 0;
      final service = CryptoQuoteService(
        baseUrl: null,
        httpClient: MockClient((_) async {
          requestCount += 1;
          return http.Response('{}', 200);
        }),
      );

      final quotes = await service.fetchQuotes(coinIds: const ['ethereum']);

      expect(requestCount, 0);
      expect(quotes, hasLength(1));
      expect(quotes.single.symbol, 'ETH');
      expect(quotes.single.source, 'coingecko-mock');
    },
  );
}
