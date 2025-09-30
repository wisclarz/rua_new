import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Color Palette
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryVariant = Color(0xFF4338CA);
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple
  static const Color secondaryVariant = Color(0xFF7C3AED);
  static const Color accentColor = Color(0xFF06B6D4); // Cyan
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFDFDFD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF8FAFC);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF2D3748);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightOutlineVariant = Color(0xFFF1F5F9);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkOnBackground = Color(0xFFF8FAFC);
  static const Color darkOnSurface = Color(0xFFE2E8F0);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF475569);
  static const Color darkOutlineVariant = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDFDFD), Color(0xFFF8FAFC)],
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEEF2FF),
        onPrimaryContainer: Color(0xFF1E1B4B),
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF3F4F6),
        onSecondaryContainer: Color(0xFF1F2937),
        tertiary: accentColor,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFECFDF5),
        onTertiaryContainer: Color(0xFF064E3B),
        error: errorColor,
        onError: Colors.white,
        errorContainer: Color(0xFFFEF2F2),
        onErrorContainer: Color(0xFF7F1D1D),
        surface: lightSurface,
        onSurface: lightOnSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurfaceVariant: lightOnSurfaceVariant,
        outline: lightOutline,
        outlineVariant: lightOutlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: darkSurface,
        onInverseSurface: darkOnSurface,
        inversePrimary: Color(0xFFA5B4FC),
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightOnBackground,
        centerTitle: true,
        titleTextStyle: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: lightOnBackground,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: lightOutline),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: lightOnSurfaceVariant,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: lightOnSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightOutlineVariant),
        ),
        color: lightSurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: lightOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      textTheme: _buildTextTheme(baseTextTheme, lightOnBackground),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF312E81),
        onPrimaryContainer: Color(0xFFEEF2FF),
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF1F2937),
        onSecondaryContainer: Color(0xFFF3F4F6),
        tertiary: accentColor,
        onTertiary: Colors.black,
        tertiaryContainer: Color(0xFF064E3B),
        onTertiaryContainer: Color(0xFFECFDF5),
        error: errorColor,
        onError: Colors.white,
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFEF2F2),
        surface: darkSurface,
        onSurface: darkOnSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: lightSurface,
        onInverseSurface: lightOnSurface,
        inversePrimary: primaryVariant,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkOnBackground,
        centerTitle: true,
        titleTextStyle: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: darkOutline),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: darkOnSurfaceVariant,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: darkOnSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkOutlineVariant),
        ),
        color: darkSurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      textTheme: _buildTextTheme(baseTextTheme, darkOnBackground),
    );
  }

  static TextTheme _buildTextTheme(TextTheme baseTheme, Color defaultColor) {
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: defaultColor,
        fontSize: 48, // Reduced from default ~57
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: defaultColor,
        fontSize: 38, // Reduced from default ~45
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 30, // Reduced from default ~36
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 28, // Reduced from default ~32
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 24, // Reduced from default ~28
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 20, // Reduced from default ~24
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 18, // Reduced from default ~22
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: defaultColor,
        fontSize: 14, // Reduced from default ~16
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: defaultColor,
        fontSize: 12, // Reduced from default ~14
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: defaultColor,
        height: 1.5,
        fontSize: 14, // Reduced from default ~16
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: defaultColor,
        height: 1.5,
        fontSize: 12, // Reduced from default ~14
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: defaultColor,
        height: 1.4,
        fontSize: 10, // Reduced from default ~12
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: defaultColor,
        fontSize: 12, // Reduced from default ~14
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: defaultColor,
        fontSize: 10, // Reduced from default ~12
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: defaultColor,
        fontSize: 9, // Reduced from default ~11
      ),
    );
  }

  // Helper methods for common UI patterns
  static BoxDecoration glassmorphicDecoration({
    Color? color,
    double borderRadius = 16,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }

  static BoxDecoration cardDecoration({
    required ColorScheme colorScheme,
    double borderRadius = 20,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: colorScheme.outlineVariant,
        width: 1,
      ),
      boxShadow: elevated ? [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }

  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    double borderRadius = 16,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}
