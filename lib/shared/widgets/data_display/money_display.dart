import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/privacy/privacy_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/money.dart';

class MoneyDisplay extends ConsumerWidget {
  const MoneyDisplay({
    required this.amount,
    this.size,
    this.weight,
    this.showSign = false,
    this.muted = false,
    super.key,
  });

  final Object amount;
  final double? size;
  final FontWeight? weight;
  final bool showSign;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    final text = switch (amount) {
      final Money money => MoneyFormatter.format(
        money,
        showSign: showSign,
        hidden: hidden,
      ),
      final num value => MoneyFormatter.twd(
        value,
        showSign: showSign,
        hidden: hidden,
      ),
      _ => throw ArgumentError.value(amount, 'amount', 'Must be num or Money'),
    };

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: muted ? AppColors.textTertiary : AppColors.textPrimary,
        fontSize: size ?? 24,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: weight ?? FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}
