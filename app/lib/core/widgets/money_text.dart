import 'package:flutter/material.dart';
import 'package:vantia/core/money/money.dart';

/// Muestra un [Money] con formato `S/ 1,234.50` y cifras tabulares.
class MoneyText extends StatelessWidget {
  const MoneyText(this.amount, {super.key, this.style, this.semanticsPrefix});

  final Money amount;
  final TextStyle? style;
  final String? semanticsPrefix;

  @override
  Widget build(BuildContext context) {
    final text = amount.format();
    return Text(
      text,
      style: (style ?? DefaultTextStyle.of(context).style).copyWith(
        fontWeight: style?.fontWeight ?? FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      semanticsLabel: '${semanticsPrefix ?? ''} ${amount.format()} soles'
          .trim(),
    );
  }
}
