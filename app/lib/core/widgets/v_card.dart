import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';

/// Tarjeta base. `highlight: true` usa el color destacado (p. ej. resumen).
class VCard extends StatelessWidget {
  const VCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(VantiaSpacing.lg),
    this.highlight = false,
    this.onTap,
    this.radius = VantiaRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? context.vColors.highlight
        : context.colors.surfaceContainerLow;
    final fg = highlight
        ? context.vColors.onHighlight
        : context.colors.onSurface;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: IconTheme.merge(
            data: IconThemeData(color: fg),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
