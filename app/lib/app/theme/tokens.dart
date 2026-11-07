import 'package:flutter/material.dart';

/// Tokens de diseño de Vantia. Toda la UI debe leer colores del `ColorScheme`
/// o de [VantiaColors]; nunca valores hex sueltos en widgets.
abstract final class VantiaPalette {
  // Marca
  static const Color blue200 = Color(0xFFA8C7FA); // primario (oscuro)
  static const Color blue700 = Color(0xFF2F5BD3); // primario (claro)
  static const Color blue50 = Color(0xFFDCE6FF);
  static const Color navy900 = Color(0xFF0E1A2B); // texto sobre primario

  // Neutros oscuros (fondo de la referencia)
  static const Color ink950 = Color(0xFF0E111A);
  static const Color ink900 = Color(0xFF141924);
  static const Color ink850 = Color(0xFF1B2130);
  static const Color ink800 = Color(0xFF232A3A);
  static const Color ink700 = Color(0xFF2E3647);
  static const Color ink400 = Color(0xFF8B93A7);

  // Neutros claros
  static const Color paper50 = Color(0xFFF6F8FC);
  static const Color paper100 = Color(0xFFEDF1F8);
  static const Color slate300 = Color(0xFFCBD3E1);
  static const Color slate600 = Color(0xFF5B6476);

  // Estados
  static const Color success = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFF4B740);
  static const Color danger = Color(0xFFFF6B6B);
}

abstract final class VantiaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Margen lateral de las pantallas.
  static const double page = 24;

  /// Espacio inferior para que el FAB y la barra no tapen contenido.
  static const double bottomSafe = 120;
}

abstract final class VantiaRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

/// Colores semánticos extra que el `ColorScheme` de Material no cubre.
@immutable
class VantiaColors extends ThemeExtension<VantiaColors> {
  const VantiaColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.muted,
    required this.highlight,
    required this.onHighlight,
  });

  final Color success;
  final Color warning;
  final Color danger;

  /// Texto secundario (subtítulos, etiquetas).
  final Color muted;

  /// Tarjeta destacada (p. ej. "Ingresos de hoy").
  final Color highlight;
  final Color onHighlight;

  static const dark = VantiaColors(
    success: VantiaPalette.success,
    warning: VantiaPalette.warning,
    danger: VantiaPalette.danger,
    muted: VantiaPalette.ink400,
    highlight: VantiaPalette.blue200,
    onHighlight: VantiaPalette.navy900,
  );

  static const light = VantiaColors(
    success: Color(0xFF138A5A),
    warning: Color(0xFFB7791F),
    danger: Color(0xFFD64545),
    muted: VantiaPalette.slate600,
    highlight: VantiaPalette.blue50,
    onHighlight: VantiaPalette.navy900,
  );

  @override
  VantiaColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? muted,
    Color? highlight,
    Color? onHighlight,
  }) => VantiaColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    muted: muted ?? this.muted,
    highlight: highlight ?? this.highlight,
    onHighlight: onHighlight ?? this.onHighlight,
  );

  @override
  VantiaColors lerp(VantiaColors? other, double t) {
    if (other == null) return this;
    return VantiaColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
    );
  }
}

extension VantiaThemeX on BuildContext {
  VantiaColors get vColors => Theme.of(this).extension<VantiaColors>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
