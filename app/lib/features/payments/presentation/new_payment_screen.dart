import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/payment_method_icon.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-20: "¿Cómo pagó el cliente?"
class NewPaymentScreen extends StatefulWidget {
  const NewPaymentScreen({super.key});

  @override
  State<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends State<NewPaymentScreen> {
  bool _withProducts = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VantiaSpacing.page,
          VantiaSpacing.md,
          VantiaSpacing.page,
          VantiaSpacing.xl,
        ),
        children: [
          Text(l10n.newPaymentQuestion, style: context.text.titleLarge),
          const SizedBox(height: VantiaSpacing.sm),
          Text(
            l10n.newPaymentSubtitle,
            style: context.text.bodyLarge?.copyWith(
              color: context.vColors.muted,
            ),
          ),
          const SizedBox(height: VantiaSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.newPaymentWithProducts),
            value: _withProducts,
            onChanged: (v) => setState(() => _withProducts = v),
          ),
          const SizedBox(height: VantiaSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: VantiaSpacing.md,
            crossAxisSpacing: VantiaSpacing.md,
            children: [
              for (final method in PaymentMethod.values)
                PaymentMethodTile(
                  method: method,
                  onTap: () => context.pushReplacement(
                    Routes.paymentForm(method.id, withProducts: _withProducts),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
