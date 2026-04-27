class Money {
  const Money(this.amount, {this.currencyCode = 'TWD'});
  const Money.twd(this.amount) : currencyCode = 'TWD';

  final num amount;
  final String currencyCode;

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.amount == amount &&
        other.currencyCode == currencyCode;
  }

  @override
  int get hashCode => Object.hash(amount, currencyCode);
}
