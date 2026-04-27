import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/formatters/money_formatter.dart';
import 'package:networth_cockpit/shared/models/money.dart';

void main() {
  test('formats Money value objects with thousands separators', () {
    expect(MoneyFormatter.format(Money.twd(2450000)), 'NT\$ 2,450,000');
    expect(
      MoneyFormatter.format(Money.twd(-1280), showSign: true),
      '-NT\$ 1,280',
    );
    expect(
      MoneyFormatter.format(Money.twd(85000), showSign: true),
      '+NT\$ 85,000',
    );
  });

  test('masks only the amount when privacy mode is enabled', () {
    expect(
      MoneyFormatter.format(Money.twd(2450000), hidden: true),
      'NT\$ ¥¥¥¥¥',
    );
  });
}
