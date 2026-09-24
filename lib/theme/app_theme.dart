import 'package:flutter/material.dart';

/// LSU brand colors. Keep color choices here so the whole app stays consistent
/// and one person can restyle the app without touching every screen.
class LsuColors {
  static const Color purple = Color(0xFF461D7C);
  static const Color gold = Color(0xFFFDD023);
}

/// The app-wide theme. TODO(team): add a dark theme variant.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: LsuColors.purple,
    primary: LsuColors.purple,
    secondary: LsuColors.gold,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F6FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: LsuColors.purple,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LsuColors.gold,
      foregroundColor: LsuColors.purple,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
