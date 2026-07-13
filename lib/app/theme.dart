import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for the premium dark theme.
class AppTheme {
  // Palette
  static const Color bg = Color(0xFF0B0F1A);
  static const Color surface = Color(0xFF141B2E);
  static const Color surfaceGlass = Color(0x33FFFFFF);
  static const Color accent = Color(0xFF6C8CFF);
  static const Color accentGlow = Color(0xFF9AB0FF);
  static const Color feltGreen = Color(0xFF1E7A52);
  static const Color textPrimary = Color(0xFFF2F5FF);
  static const Color textMuted = Color(0xFF98A2C0);

  // Board colors (used by chess)
  static const Color boardLight = Color(0xFFE9E2D0);
  static const Color boardDark = Color(0xFF6E4A2E);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B0F1A), Color(0xFF1A2138)],
  );

  static const double radius = 20.0;
  static const double gap = 16.0;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        surface: surface,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
