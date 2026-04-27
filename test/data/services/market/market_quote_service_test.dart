import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/market/market_quote_service.dart';

void main() {
  test(
    'market quote service falls back to mock quotes when endpoints fail',
    () async {
      final service = MarketQuoteService(
        twseEndpoint: 'https://example.com/twse',
        tpexEndpoint: 'https://example.com/tpex',
        httpClient: MockClient((request) async => http.Response('oops', 500)),
      );

      final quotes = await service.fetchQuotes(symbols: const ['2330', '8069']);

      expect(quotes, isNotEmpty);
      expect(
        quotes.map((quote) => quote.symbol),
        containsAll(['2330', '8069']),
      );
      expect(quotes.every((quote) => quote.source.contains('mock')), isTrue);
    },
  );
}
