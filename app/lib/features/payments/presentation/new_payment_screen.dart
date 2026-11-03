import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/payment_method_icon.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/l10n/l10n.dart';

/// Selector "¿Cómo pagó el cliente?". En M0 solo la UI; la navegación a los
/// formularios llega con F-20/F-21/F-22.
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
                  // TODO(F-20): navegar al formulario según el método.
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.comingSoon('F-20'))),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
