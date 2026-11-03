import 'package:flutter/material.dart';

enum VButtonVariant { primary, outlined, text }

/// Botón principal. Muestra un spinner y se deshabilita mientras `loading`.
class VButton extends StatelessWidget {
  const VButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
    this.variant = VButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final VButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final callback = loading ? null : onPressed;
    final child = loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(label);

    return switch (variant) {
      VButtonVariant.primary when icon != null && !loading => FilledButton.icon(
        onPressed: callback,
        icon: Icon(icon),
        label: child,
      ),
      VButtonVariant.primary => FilledButton(onPressed: callback, child: child),
      VButtonVariant.outlined when icon != null && !loading =>
        OutlinedButton.icon(
          onPressed: callback,
          icon: Icon(icon),
          label: child,
        ),
      VButtonVariant.outlined => OutlinedButton(
        onPressed: callback,
        child: child,
      ),
      VButtonVariant.text => TextButton(onPressed: callback, child: child),
    };
  }
}
