// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette — dark cipher aesthetic
  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color card = Color(0xFF1A1A26);
  static const Color border = Color(0xFF2A2A40);
  static const Color accent = Color(0xFF00FFB2); // neon mint
  static const Color accentDim = Color(0xFF00FFB220);
  static const Color accentGlow = Color(0xFF00FFB260);
  static const Color warning = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFFEEEEFF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF444460);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: warning,
          surface: surface,
          background: bg,
          onPrimary: bg,
          onSecondary: bg,
          onSurface: textPrimary,
          onBackground: textPrimary,
        ),
        textTheme: GoogleFonts.spaceMonoTextTheme(
          const TextTheme(
            displayLarge: TextStyle(color: textPrimary, letterSpacing: -2),
            displayMedium: TextStyle(color: textPrimary),
            titleLarge: TextStyle(color: textPrimary, letterSpacing: 0.5),
            bodyLarge: TextStyle(color: textPrimary),
            bodyMedium: TextStyle(color: textSecondary),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceMono(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          iconTheme: const IconThemeData(color: accent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: bg,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            textStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          labelStyle: GoogleFonts.spaceMono(color: textSecondary),
          hintStyle: GoogleFonts.spaceMono(color: textMuted),
        ),
        dividerColor: border,
        cardColor: card,
      );
}
