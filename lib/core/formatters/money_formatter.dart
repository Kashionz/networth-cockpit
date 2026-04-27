import 'package:intl/intl.dart';

import '../../shared/models/money.dart';

class MoneyFormatter {
  const MoneyFormatter._();

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern(
    'en_US',
  );

  static String format(
    Money money, {
    bool showSign = false,
    bool hidden = false,
  }) {
    return _formatAmount(
      money.amount,
      currencyPrefix: _prefixFor(money.currencyCode),
      showSign: showSign,
      hidden: hidden,
    );
  }

  static String twd(num amount, {bool showSign = false, bool hidden = false}) {
    return _formatAmount(
      amount,
      currencyPrefix: 'NT\$',
      showSign: showSign,
      hidden: hidden,
    );
  }

  static String _formatAmount(
    num amount, {
    required String currencyPrefix,
    required bool showSign,
    required bool hidden,
  }) {
    final prefix = amount > 0 && showSign
        ? '+'
        : amount < 0 && showSign
        ? '-'
        : '';
    final body = hidden ? '¥¥¥¥¥' : _numberFormat.format(amount.abs());
    return '$prefix$currencyPrefix $body';
  }

  static String _prefixFor(String currencyCode) {
    return switch (currencyCode) {
      'TWD' => 'NT\$',
      _ => currencyCode,
    };
  }
}
