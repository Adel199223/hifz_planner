import 'package:flutter/material.dart';

class QuranThemes {
  static ThemeData sepia() {
    const scaffoldBackground = Color(0xFFF8EBD5);
    const surface = Color(0xFFFFF7EA);
    const surfaceAlt = Color(0xFFEFE2CD);
    const border = Color(0xFFDBCCB3);
    const text = Color(0xFF272727);
    const strongText = Color(0xFF010101);
    const mutedText = Color(0xFF666666);
    const accent = Color(0xFF72603F);
    const secondaryAccent = Color(0xFF22A5AD);
    const error = Color(0xFFC50000);

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondary: secondaryAccent,
      onSecondary: Colors.white,
      tertiary: secondaryAccent,
      onTertiary: Colors.white,
      surface: surface,
      onSurface: text,
      error: error,
      onError: Colors.white,
      outline: border,
      outlineVariant: border,
      surfaceContainerHighest: surfaceAlt,
      surfaceContainerHigh: surfaceAlt,
      surfaceContainer: surfaceAlt,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: surface,
      dividerColor: border,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: text),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: text),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: mutedText),
        titleLarge: base.textTheme.titleLarge?.copyWith(color: strongText),
        titleMedium: base.textTheme.titleMedium?.copyWith(color: strongText),
        headlineSmall:
            base.textTheme.headlineSmall?.copyWith(color: strongText),
      ),
      iconTheme: const IconThemeData(color: text),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surface,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
      ),
    );
  }

  static ThemeData dark() {
    const scaffoldBackground = Color(0xFF1F2125);
    const surface = Color(0xFF1F2125);
    const surfaceAlt = Color(0xFF343A40);
    const border = Color(0xFF464B50);
    const text = Color(0xFFE7E9EA);
    const strongText = Color(0xFFFFFFFF);
    const mutedText = Color(0xFFDEE2E6);
    const accent = Color(0xFF2CA4AB);
    const error = Color(0xFFF33F3F);

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      tertiary: accent,
      onTertiary: Colors.white,
      surface: surface,
      onSurface: text,
      error: error,
      onError: Colors.black,
      outline: border,
      outlineVariant: border,
      surfaceContainerHighest: surfaceAlt,
      surfaceContainerHigh: surfaceAlt,
      surfaceContainer: surfaceAlt,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: surface,
      dividerColor: border,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: text),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: text),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: mutedText),
        titleLarge: base.textTheme.titleLarge?.copyWith(color: strongText),
        titleMedium: base.textTheme.titleMedium?.copyWith(color: strongText),
        headlineSmall:
            base.textTheme.headlineSmall?.copyWith(color: strongText),
      ),
      iconTheme: const IconThemeData(color: text),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surfaceAlt,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
      ),
    );
  }
}
