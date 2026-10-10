import 'package:flutter/material.dart';

class AppTheme {
  // Premium Color System
  static const Color deepBurgundy = Color(0xFF4A0F16);
  static const Color darkBackground = Color(0xFF2B0A0E);
  static const Color elevatedBurgundy = Color(0xFF3A1016);
  static const Color secondaryMaroon = Color(0xFF51151C);

  static const Color primaryGold = Color(0xFFE5A43A);
  static const Color secondarySaffron = Color(0xFFC97A1E);

  static const Color primaryIvory = Color(0xFFF7F1E8);
  static const Color warmText = Color(0xFFD9C9B3);
  static const Color mutedText = Color(0xFFB39A7A);

  static const String currentFontFamily = 'FedraSansPro';
  static const String serifFontFamily = 'FedraSerifA';
  static const String sindhiHeadingFont = 'SaremAsifa';
  static const String sindhiRegularFont = 'MBSaremIqra';

  // ===========================================================================
  // UNIFIED TYPOGRAPHY ROLE SYSTEM
  // ===========================================================================

  /// App Bar Title: FedraSerifA, 20.0 pt, bold
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: serifFontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );

  /// Main Section Title: FedraSerifA, 20.0 pt, bold
  static const TextStyle sectionTitleMain = TextStyle(
    fontFamily: serifFontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );

  /// Sheet & Dialog Title: FedraSerifA, 18.0 pt, bold
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: serifFontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
  );

  /// Main Card Title: FedraSerifA, 18.0 pt, bold
  static const TextStyle cardTitleMain = TextStyle(
    fontFamily: serifFontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
  );

  /// Compact Card Title: FedraSerifA, 16.0 pt, bold
  static const TextStyle cardTitleCompact = TextStyle(
    fontFamily: serifFontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
  );

  /// Section Header: FedraSansPro, 12.0 pt, bold, spacing 0.8
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: currentFontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );

  /// Home Reading Progress Card Title: FedraSerifA, 22.0 pt, bold
  static const TextStyle homeReadingCardTitle = TextStyle(
    fontFamily: serifFontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
  );

  // Helper method for Sindhi text styling
  static TextStyle sindhiHeadingStyle(BuildContext context) {
    return TextStyle(
      fontFamily: sindhiHeadingFont,
      fontWeight: FontWeight.bold,
      fontSize: 26, // Readable heading size
      height: 1.4,
      foreground: Paint()
        ..color = Theme.of(context).colorScheme.onSurface
        ..colorFilter = ColorFilter.mode(
          Theme.of(context).colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      fontFeatures: const [FontFeature('COLR', 0), FontFeature('CPAL', 0)],
    );
  }

  static TextStyle sindhiRegularStyle(BuildContext context) {
    return TextStyle(
      fontFamily: sindhiRegularFont,
      fontSize: 20, // Generous, readable size
      height: 1.6,
      foreground: Paint()
        ..color = Theme.of(context).colorScheme.onSurface
        ..colorFilter = ColorFilter.mode(
          Theme.of(context).colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      fontFeatures: const [FontFeature('COLR', 0), FontFeature('CPAL', 0)],
    );
  }

  // Light Theme specific colors (Derived for a warm ivory feel)
  static const Color backgroundIvory = primaryIvory;
  static const Color surfaceLight = Color(
    0xFFEFE8DE,
  ); // Slightly darker ivory for surfaces
  static const Color textPrimaryDark = deepBurgundy;
  static const Color textSecondaryDarkMuted = secondaryMaroon;
  static const Color dividerLight = Color(0xFFE5DCD0);

  // Unified Card & Container Borders
  static const Color cardBorderLight = Color(0xFFE5D5C5);
  static const Color cardBorderDark = Color(
    0x59E5A43A,
  ); // Warm Sacred Gold Rim (35% alpha)

  static Color cardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBorderDark
        : cardBorderLight;
  }

  // Unified Card & Container Text Colors
  static const Color cardTextDarkBrown = Color(0xFF4A2B2B);
  static const Color cardTextIvory = Color(0xFFE5D5C5);

  static Color cardTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardTextIvory
        : cardTextDarkBrown;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundIvory,
      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        secondary: secondarySaffron,
        surface: surfaceLight,
        surfaceContainerHighest: Color(0xFFEBE2D5),
        onSurface: textPrimaryDark,
        onSurfaceVariant: textSecondaryDarkMuted,
        onPrimary: deepBurgundy,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderLight, width: 1),
        ),
        color: surfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBurgundy,
        foregroundColor: primaryIvory,
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryIvory,
        ),
      ),
      textTheme: _applyLiningFigures(
        const TextTheme(
          headlineMedium: TextStyle(color: textPrimaryDark),
          headlineSmall: TextStyle(color: textPrimaryDark),
          titleLarge: TextStyle(color: textPrimaryDark),
          titleMedium: TextStyle(color: textPrimaryDark),
          bodyLarge: TextStyle(color: textPrimaryDark),
          bodyMedium: TextStyle(color: textPrimaryDark),
          bodySmall: TextStyle(color: textSecondaryDarkMuted),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          side: const BorderSide(color: dividerLight),
          backgroundColor: surfaceLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBurgundy,
          foregroundColor: primaryIvory,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 24,
      ),
      fontFamily: currentFontFamily,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      dividerColor: cardBorderDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: secondarySaffron,
        surface: elevatedBurgundy,
        surfaceContainerHighest: secondaryMaroon,
        onSurface: primaryIvory,
        onSurfaceVariant: mutedText,
        onPrimary: darkBackground,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderDark, width: 1),
        ),
        color: elevatedBurgundy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBurgundy,
        foregroundColor: primaryGold,
        elevation: 4,
        shadowColor: Colors.black45,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: serifFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryGold,
        ),
      ),
      textTheme: _applyLiningFigures(
        const TextTheme(
          headlineMedium: TextStyle(color: primaryIvory),
          headlineSmall: TextStyle(color: primaryIvory),
          titleLarge: TextStyle(color: primaryIvory),
          titleMedium: TextStyle(color: primaryIvory),
          bodyLarge: TextStyle(color: warmText),
          bodyMedium: TextStyle(color: warmText),
          bodySmall: TextStyle(color: mutedText),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryIvory,
          side: const BorderSide(color: cardBorderDark),
          backgroundColor: elevatedBurgundy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorderDark,
        thickness: 1,
        space: 24,
      ),
      fontFamily: currentFontFamily,
    );
  }

  /// Enforces FedraSerifA for all headings/titles and FedraSansPro for all other text across the entire app,
  /// matching Isha Foundation's typography system.
  static TextTheme _applyLiningFigures(TextTheme base) {
    const features = [FontFeature.liningFigures()];
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: serifFontFamily,
        fontFeatures: features,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: currentFontFamily,
        fontFeatures: features,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: currentFontFamily,
        fontFeatures: features,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: currentFontFamily,
        fontFeatures: features,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: currentFontFamily,
        fontFeatures: features,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: currentFontFamily,
        fontFeatures: features,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: currentFontFamily,
        fontFeatures: features,
      ),
    );
  }
}
