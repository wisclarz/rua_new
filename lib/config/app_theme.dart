import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🌙 Deep Purple Palette - HTML Dark Theme ile Uyumlu
  
  // Ana Mor Tonları - HTML primary: #7f13ec ile uyumlu
  static const Color deepPurple = Color(0xFF7f13ec); // HTML primary
  static const Color darkPurple = Color(0xFF6900BC); // Koyu variant
  static const Color richPurple = Color(0xFF8a15ff); // Zengin mor
  static const Color softPurple = Color(0xFF9B4DE0); // Yumuşak mor
  static const Color lightPurple = Color(0xFFB87FE8); // Açık mor
  
  // Destek Tonları - Mor bazlı (pembe yok)
  static const Color deepViolet = Color(0xFF5A00A8); // Derin violet
  static const Color softViolet = Color(0xFF8B2FC9); // Yumuşak violet
  static const Color lightViolet = Color(0xFFA865D4); // Açık violet
  
  // Orkide & Lavanta - Mor tonlarında
  static const Color orchid = Color(0xFF8F27C3); // Orkide (mor)
  static const Color lavender = Color(0xFF9961CB); // Lavanta (mor)
  
  // Destekleyici Renkler
  static const Color moonlightBlue = Color(0xFF60A5FA); // Ay ışığı mavisi
  static const Color starYellow = Color(0xFFFBBF24); // Yıldız sarısı
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  
  // 🌅 Light Theme Colors - Daha Koyu, Mor Ağırlıklı
  static const Color lightBackground = Color(0xFFF3E8FF); // Mor tinted background
  static const Color lightSurface = Color(0xFFFAF5FF); // Açık mor surface
  static const Color lightSurfaceVariant = Color(0xFFE9D5FF); // Mor surface variant
  static const Color lightOnBackground = Color(0xFF1F1B24); // Koyu metin
  static const Color lightOnSurface = Color(0xFF2D2535); // Surface metin
  static const Color lightOnSurfaceVariant = Color(0xFF6B5B7B); // İkincil metin
  static const Color lightOutline = Color(0xFFD8B4FE); // Mor border
  static const Color lightOutlineVariant = Color(0xFFEDE9FE); // Açık mor border
  
  // 🌙 Dark Theme Colors - HTML Dark Theme ile Tam Uyumlu
  static const Color darkBackground = Color(0xFF120B1C); // HTML: #120B1C
  static const Color darkSurface = Color(0xFF1F152E); // HTML: #1F152E (card-dark)
  static const Color darkSurfaceVariant = Color(0xFF2D1B4E); // Variant
  static const Color darkOnBackground = Color(0xFFF8FAFC); // Açık metin
  static const Color darkOnSurface = Color(0xFFEDE9FE); // Surface metin
  static const Color darkOnSurfaceVariant = Color(0xFFBFB3D1); // İkincil metin
  static const Color darkOutline = Color(0xFF3D2A5C); // Border
  static const Color darkOutlineVariant = Color(0xFF2D1B4E); // Subtle border
  
  // 🌈 Dreamy Gradients - Mor Gradientleri (pembe yok)
  static const LinearGradient dreamyPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6900BC), // Deep Purple
      Color(0xFF7D1ACF), // Rich Purple
      Color(0xFF9B4DE0), // Soft Purple
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient nightDreamGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF5500A3), // Çok koyu mor
      Color(0xFF6900BC), // Derin mor
      Color(0xFF7D1ACF), // Parlak mor
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8D5F5), // Açık mor
      Color(0xFFF0E5F9), // Çok açık mor
      Color(0xFFF5F0FA), // Beyaza yakın mor
    ],
  );
  
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0624), // Çok koyu
      Color(0xFF1A0F2E), // Koyu mor
      Color(0xFF2D1B4E), // Orta koyu
    ],
  );
  
  static const LinearGradient cardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE3D2F0), // Koyu lavanta
      Color(0xFFF0E5F9), // Açık mor
    ],
  );
  
  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D1B4E), // Koyu mor
      Color(0xFF3D2A5C), // Orta mor
    ],
  );

  // 🎨 Light Theme
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: deepPurple,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDDD6FE), // Koyu lavanta
        onPrimaryContainer: Color(0xFF2D1B4E),
        
        secondary: softPurple,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFCCEE8), // Koyu pembe
        onSecondaryContainer: Color(0xFF831843),
        
        tertiary: lavender,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFDDD6FE),
        onTertiaryContainer: Color(0xFF4C1D95),
        
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF7F1D1D),
        
        surface: lightSurface,
        onSurface: lightOnSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurfaceVariant: lightOnSurfaceVariant,
        
        outline: lightOutline,
        outlineVariant: lightOutlineVariant,
        
        shadow: Color(0x207C3AED),
        scrim: Color(0x807C3AED),
        inverseSurface: darkSurface,
        onInverseSurface: darkOnSurface,
        inversePrimary: softPurple,
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
          fontSize: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          side: const BorderSide(color: deepPurple, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: lightOutline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: deepPurple, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: errorRed, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: lightOnSurfaceVariant,
          fontSize: 14,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: lightOnSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: deepPurple.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: lightOutline,
            width: 1.5,
          ),
        ),
        color: lightSurface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: lightSurface,
        selectedItemColor: deepPurple,
        unselectedItemColor: lightOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceVariant,
        selectedColor: deepPurple,
        labelStyle: baseTextTheme.bodySmall?.copyWith(
          color: deepPurple,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      dividerTheme: const DividerThemeData(
        color: lightOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      
      textTheme: _buildTextTheme(baseTextTheme, lightOnBackground),
    );
  }

  // 🌙 Dark Theme
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: softPurple,
        onPrimary: Color(0xFF1F1B24),
        primaryContainer: darkPurple,
        onPrimaryContainer: Color(0xFFEDE9FE),
        
        secondary: lightViolet,
        onSecondary: Color(0xFF1F1B24),
        secondaryContainer: Color(0xFF831843),
        onSecondaryContainer: Color(0xFFFCCEE8),
        
        tertiary: lavender,
        onTertiary: Color(0xFF1F1B24),
        tertiaryContainer: Color(0xFF4C1D95),
        onTertiaryContainer: Color(0xFFDDD6FE),
        
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFEE2E2),
        
        surface: darkSurface,
        onSurface: darkOnSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkOnSurfaceVariant,
        
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
        
        shadow: Color(0x40000000),
        scrim: Color(0xFF000000),
        inverseSurface: lightSurface,
        onInverseSurface: lightOnSurface,
        inversePrimary: deepPurple,
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
          fontSize: 20,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: softPurple,
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: softPurple,
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: softPurple,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          side: const BorderSide(color: softPurple, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: softPurple,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: darkOutline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: softPurple, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: errorRed, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: darkOnSurfaceVariant,
          fontSize: 14,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: darkOnSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: darkOutline,
            width: 1.5,
          ),
        ),
        color: darkSurface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkSurface,
        selectedItemColor: softPurple,
        unselectedItemColor: darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: softPurple,
        foregroundColor: darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        selectedColor: softPurple,
        labelStyle: baseTextTheme.bodySmall?.copyWith(
          color: softPurple,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: defaultColor,
        fontSize: 48,
        height: 1.1,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: defaultColor,
        fontSize: 38,
        height: 1.15,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: defaultColor,
        fontSize: 30,
        height: 1.2,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 28,
        height: 1.25,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 24,
        height: 1.3,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 20,
        height: 1.3,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultColor,
        fontSize: 18,
        height: 1.4,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: defaultColor,
        fontSize: 15,
        height: 1.4,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: defaultColor,
        fontSize: 13,
        height: 1.4,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: defaultColor,
        height: 1.6,
        fontSize: 15,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: defaultColor,
        height: 1.5,
        fontSize: 13,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: defaultColor,
        height: 1.5,
        fontSize: 11,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: defaultColor,
        fontSize: 15,
        height: 1.2,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: defaultColor,
        fontSize: 12,
        height: 1.2,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: defaultColor,
        fontSize: 10,
        height: 1.2,
      ),
    );
  }

  // 🎨 Helper Methods
  static BoxDecoration glassmorphicDecoration({
    Color? color,
    double borderRadius = 20,
    double opacity = 0.15,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      color: (color ?? deepPurple).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: withBorder
          ? Border.all(
              color: (color ?? deepPurple).withValues(alpha: 0.4),
              width: 1.5,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: (color ?? deepPurple).withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
  
  static BoxDecoration dreamyCardDecoration({
    bool isDark = false,
    double borderRadius = 24,
  }) {
    return BoxDecoration(
      gradient: isDark ? cardGradientDark : cardGradientLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? darkOutline : lightOutline,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : deepPurple.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
  
  static List<BoxShadow> softShadow({
    Color? color,
    double opacity = 0.15,
  }) {
    return [
      BoxShadow(
        color: (color ?? deepPurple).withValues(alpha: opacity),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }
  
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'mutlu':
      case 'heyecanlı':
        return successGreen;
      case 'kaygılı':
        return starYellow;
      case 'korkulu':
      case 'huzursuz':
        return errorRed;
      case 'huzurlu':
      case 'sakin':
        return lavender;
      case 'şaşkın':
        return moonlightBlue;
      default:
        return deepPurple;
    }
  }
  
  static Color get shimmerBaseColor => lightSurfaceVariant;
  static Color get shimmerHighlightColor => lightSurface;
  static Color get darkShimmerBaseColor => darkSurfaceVariant;
  static Color get darkShimmerHighlightColor => darkSurface;
}