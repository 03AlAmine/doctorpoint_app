import 'package:flutter/material.dart';

class AppTheme {
  // Palette de couleurs moderne - Design System médical élégant
  static const Color primaryColor = Color(0xFF4A6FFF); // Bleu moderne
  static const Color secondaryColor = Color(0xFF00D4AA); // Turquoise frais
  static const Color accentColor = Color(0xFF9B7BFE); // Violet élégant
  static const Color backgroundColor = Color(0xFFFAFBFE); // Blanc cassé très clair
  static const Color surfaceColor = Color(0xFFFFFFFF); // Blanc pur pour surfaces
  static const Color textColor = Color(0xFF1A1D47); // Bleu foncé profond
  static const Color textSecondary = Color(0xFF6B7280); // Gris texte
  static const Color greyColor = Color(0xFF94A3B8); // Gris moyen moderne
  static const Color lightGrey = Color(0xFFF1F5F9); // Gris très clair
  static const Color successColor = Color(0xFF10B981); // Vert succès moderne
  static const Color warningColor = Color(0xFFF59E0B); // Orange ambre
  static const Color dangerColor = Color(0xFFEF4444); // Rouge vif
  static const Color infoColor = Color(0xFF3B82F6); // Bleu info moderne

  // Couleurs supplémentaires
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color shadowColor = Color(0x1A1A1D47);
  static const Color overlayColor = Color(0x0D000000);
  static const Color shimmerColor = Color(0xFFE9EDF2);

  // Dégradés prédéfinis
  static Gradient get primaryGradient => LinearGradient(
        colors: [primaryColor, Color(0xFF6678FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Gradient get secondaryGradient => LinearGradient(
        colors: [secondaryColor, Color(0xFF00E5B9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Gradient get accentGradient => LinearGradient(
        colors: [accentColor, Color(0xFFB89CFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Thème principal
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      onSurface: textColor,
      onBackground: textColor,
      error: dangerColor,
      outline: borderColor,
    ),
    
    // AppBar élégant
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: textColor, size: 24),
      actionsIconTheme: IconThemeData(color: textColor, size: 24),
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: -0.3,
      ),
      centerTitle: false,
      toolbarHeight: 70,
    ),

    // Typographie moderne
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textColor,
        fontFamily: 'Poppins',
        letterSpacing: -1.2,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: textColor,
        fontFamily: 'Poppins',
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textColor,
        fontFamily: 'Poppins',
        letterSpacing: -0.6,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        fontFamily: 'Poppins',
        letterSpacing: -0.3,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: 'Poppins',
        letterSpacing: -0.2,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: 'Poppins',
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: 'Poppins',
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: 'Poppins',
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        fontFamily: 'Poppins',
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: greyColor,
        fontFamily: 'Poppins',
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Poppins',
        height: 1.2,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        fontFamily: 'Poppins',
        height: 1.2,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: greyColor,
        fontFamily: 'Poppins',
        height: 1.2,
      ),
    ),

    // Boutons élégants
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: greyColor,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: borderColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // Champs de saisie modernes
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(
        color: greyColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: dangerColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: greyColor,
      suffixIconColor: greyColor,
    ),

    // Cartes élégantes
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
    ),

    // Dialogues modernes
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
        fontFamily: 'Poppins',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        fontFamily: 'Poppins',
      ),
    ),

    // SnackBar élégantes
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: textColor,
      contentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      actionTextColor: secondaryColor,
    ),

    // Diviseurs modernes
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 0,
    ),

    // Badges et puces
    chipTheme: ChipThemeData(
      backgroundColor: lightGrey,
      selectedColor: primaryColor.withOpacity(0.1),
      disabledColor: lightGrey,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    ),
  );

  // Styles textuels réutilisables
  static TextStyle get headlineLarge => const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: textColor,
        fontFamily: 'Poppins',
        letterSpacing: -1.5,
        height: 1.1,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        fontFamily: 'Poppins',
        letterSpacing: -1.0,
        height: 1.2,
      );

  static TextStyle get subtitleLarge => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        fontFamily: 'Poppins',
        height: 1.6,
      );

  static TextStyle get subtitleMedium => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        fontFamily: 'Poppins',
        height: 1.6,
      );

  // Décoration de cartes élégantes
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.05),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: -12,
            offset: const Offset(0, 24),
          ),
        ],
      );

  static BoxDecoration get gradientCardDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: primaryGradient,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      );

  static BoxDecoration get inputDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Animation curves modernes
  static Curve get fastOutSlowInCurve => Curves.fastOutSlowIn;
  static Curve get easeInOutCubic => Curves.easeInOutCubic;
  static Duration get fastAnimationDuration => const Duration(milliseconds: 200);
  static Duration get mediumAnimationDuration => const Duration(milliseconds: 300);
  static Duration get slowAnimationDuration => const Duration(milliseconds: 500);

  // Espacements responsive
  static EdgeInsets get screenPadding => const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      );

  static EdgeInsets get cardPadding => const EdgeInsets.all(24);
  static EdgeInsets get sectionPadding => const EdgeInsets.only(
        top: 40,
        bottom: 32,
        left: 24,
        right: 24,
      );

  // Tailles responsive
  static double get maxContentWidth => 1200;
  static double get borderRadiusSmall => 8;
  static double get borderRadiusMedium => 12;
  static double get borderRadiusLarge => 20;
  static double get borderRadiusXLarge => 32;

  // Tailles d'icônes
  static double get iconSizeSmall => 20;
  static double get iconSizeMedium => 24;
  static double get iconSizeLarge => 32;
  static double get iconSizeXLarge => 48;
}