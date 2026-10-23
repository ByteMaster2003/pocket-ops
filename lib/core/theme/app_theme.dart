import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1E293B);
  static const Color cardColor = Color(0xFF131D2E);

  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryVariant = Color(0xFF00B0FF);
  static const Color accent = Color(0xFF38BDF8);

  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);

  static ThemeData get darkTheme {
    final interFont = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: interFont,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      cardColor: cardColor,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Color(0xFF001E28),
        onSurface: Color(0xFFF1F5F9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: interFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF001E28),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontFamily: interFont,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            fontFamily: interFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
    );
  }

  // Monospace font style for code and terminal
  static TextStyle terminalFont({
    double fontSize = 13.5,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: 1.25,
    );
  }
}
