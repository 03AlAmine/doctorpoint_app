import 'package:flutter/material.dart';

class AppColors {
  // Palette principale alignée avec AppTheme
  static const Color primary = Color(0xFF4A6FFF);
  static const Color secondary = Color(0xFF00D4AA);
  static const Color accent = Color(0xFF9B7BFE);
  static const Color background = Color(0xFFFAFBFE);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1A1D47);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF94A3B8);
  
  // États et feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Bordures et séparateurs
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  
  // Surfaces et arrière-plans
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color surfaceDisabled = Color(0xFFF1F5F9);
  
  // Ombres
  static const Color shadowLight = Color(0x1A1A1D47);
  static const Color shadowMedium = Color(0x331A1D47);
  static const Color shadowDark = Color(0x4D1A1D47);
  
  // Dégradés prédéfinis
  static Gradient get primaryGradient => const LinearGradient(
        colors: [primary, Color(0xFF6678FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      
  static Gradient get secondaryGradient => const LinearGradient(
        colors: [secondary, Color(0xFF00E5B9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      
  static Gradient get accentGradient => const LinearGradient(
        colors: [accent, Color(0xFFB89CFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}