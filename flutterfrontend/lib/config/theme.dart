import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Clean, Minimal, Farmer-First White & Green
  static const Color primaryGreen = Color(0xFF2E7D32); // Agriculture Deep Green
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color paleGreen = Color(0xFFE8F5E9);
  static const Color accentGreen = Color(0xFF81C784);

  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFF9FAF9);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF1A202C);
  static const Color textMuted = Color(0xFF718096);
  static const Color userBubbleColor = Color(0xFFF0FDF4); // Soft subtle mint
  static const Color errorRed = Color(0xFFE53E3E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: lightGreen,
        surface: surfaceWhite,
        error: errorRed,
        onPrimary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: textDark, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textDark, height: 1.4),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderGrey, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: borderGrey),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
