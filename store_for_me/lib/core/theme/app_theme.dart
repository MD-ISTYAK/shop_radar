import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Premium Palette - Deep Indigo & Slate
  static const Color primary = Color(0xFF6366F1);       // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8);   // Indigo 400
  static const Color primaryDark = Color(0xFF4F46E5);    // Indigo 600
  static const Color secondary = Color(0xFF10B981);      // Emerald 500
  static const Color accent = Color(0xFFF59E0B);         // Amber 500

  // Surface Colors
  static const Color background = Color(0xFFF8FAFC);     // Slate 50
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color glassBackground = Color(0x1AFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);    // Slate 900
  static const Color textSecondary = Color(0xFF475569);  // Slate 600
  static const Color textLight = Color(0xFF94A3B8);      // Slate 400

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF020617); // Slate 950
  static const Color darkSurface = Color(0xFF0F172A);    // Slate 900
  static const Color darkCard = Color(0xFF1E293B);       // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextLight = Color(0xFF64748B);

  static const Color error = Color(0xFFEF4444);          // Red 500
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color divider = Color(0xFFE2E8F0);
  static const Color darkDivider = Color(0xFF334155);
  
  static const Color shadow = Color(0x0D0F172A);

  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);
  static const Color darkShimmerBase = Color(0xFF1E293B);
  static const Color darkShimmerHighlight = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final Color surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final Color txtPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final Color txtSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final Color dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: surfaceColor,
        background: bgColor,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: bgColor,
      
      // Modern Typography using Poppins for headings and Inter for body
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: txtPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: txtSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: txtSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: bgColor,
        foregroundColor: txtPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkCard : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: dividerColor.withValues(alpha: 0.5), width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
        hintStyle: GoogleFonts.inter(color: AppColors.textLight),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
