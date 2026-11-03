import 'package:flutter/material.dart';
import 'package:vantia/core/widgets/placeholder_screen.dart';
import 'package:vantia/l10n/l10n.dart';

class CashRegisterScreen extends StatelessWidget {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: context.l10n.titleCashRegister,
    featureId: 'F-40',
  );
}
