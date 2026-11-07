import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/widgets/v_text_field.dart';

/// Campo de monto en soles. Acepta `10`, `10.50`, `10,50`.
class MoneyField extends StatelessWidget {
  const MoneyField({
    required this.label,
    required this.controller,
    super.key,
    this.hint,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  /// Lee el valor del controlador (0 si está vacío, null si es inválido).
  static Money? read(TextEditingController c) =>
      c.text.trim().isEmpty ? const Money.zero() : Money.tryParse(c.text);

  @override
  Widget build(BuildContext context) => VTextField(
    label: label,
    hint: hint,
    controller: controller,
    prefixText: 'S/ ',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: textInputAction,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      LengthLimitingTextInputFormatter(12),
    ],
    validator: validator,
    onChanged: onChanged,
  );
}
