import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';

abstract final class AppTheme {
  static const String fontFamily = 'Poppins';

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: VantiaPalette.blue200,
      onPrimary: VantiaPalette.navy900,
      primaryContainer: Color(0xFF1C2A44),
      onPrimaryContainer: VantiaPalette.blue200,
      secondary: VantiaPalette.blue200,
      onSecondary: VantiaPalette.navy900,
      error: VantiaPalette.danger,
      onError: VantiaPalette.navy900,
      surface: VantiaPalette.ink950,
      onSurface: Color(0xFFE6E9F0),
      surfaceContainerLowest: VantiaPalette.ink950,
      surfaceContainerLow: VantiaPalette.ink900,
      surfaceContainer: VantiaPalette.ink850,
      surfaceContainerHigh: VantiaPalette.ink800,
      surfaceContainerHighest: VantiaPalette.ink700,
      onSurfaceVariant: VantiaPalette.ink400,
      outline: VantiaPalette.ink700,
      outlineVariant: VantiaPalette.ink800,
    );
    return _build(scheme, VantiaColors.dark);
  }

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: VantiaPalette.blue700,
      onPrimary: Colors.white,
      primaryContainer: VantiaPalette.blue50,
      onPrimaryContainer: VantiaPalette.navy900,
      secondary: VantiaPalette.blue700,
      onSecondary: Colors.white,
      error: Color(0xFFD64545),
      onError: Colors.white,
      surface: VantiaPalette.paper50,
      onSurface: Color(0xFF151A24),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: VantiaPalette.paper100,
      surfaceContainerHigh: Color(0xFFE4E9F2),
      surfaceContainerHighest: Color(0xFFDCE2EC),
      onSurfaceVariant: VantiaPalette.slate600,
      outline: VantiaPalette.slate300,
      outlineVariant: VantiaPalette.paper100,
    );
    return _build(scheme, VantiaColors.light);
  }

  static ThemeData _build(ColorScheme scheme, VantiaColors extra) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [extra],
    );
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(VantiaRadius.md),
      borderSide: BorderSide(color: scheme.outline),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VantiaRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VantiaRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VantiaRadius.md),
          ),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.surfaceContainerHigh,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHigh,
        ),
      ),
    );
  }
}
