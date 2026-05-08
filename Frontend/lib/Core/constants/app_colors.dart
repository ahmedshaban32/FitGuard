import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C5CE7); // Purple/Blue
  static const Color primaryDark = Color(0xFF5849C4);
  static const Color secondary = Color(0xFF00D9FF); // Cyan

  // Background Colors (Dark Theme)
  static const Color background = Color(0xFF0F0F1E); // Very dark blue
  static const Color surface = Color(0xFF1A1A2E); // Dark surface
  static const Color cardBackground = Color(0xFF16213E); // Card background

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C1);
  static const Color textTertiary = Color(0xFF6B7280);

  // Accent Colors
  static const Color success = Color(0xFF00D9A0);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF42A5F5);

  // Macro Colors
  static const Color protein = Color(0xFF6C5CE7); // Purple
  static const Color carbs = Color(0xFF00D9FF); // Cyan
  static const Color fats = Color(0xFFFFA726); // Orange

  // Status Colors
  static const Color calories = Color(0xFFFF6B6B);
  static const Color steps = Color(0xFF00D9A0);
  static const Color active = Color(0xFF6C5CE7);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00D9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00D9FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Tag/Badge Colors
  static const Color tagIntense = Color(0xFFFF5252);
  static const Color tagIntermediate = Color(0xFFFFA726);
  static const Color tagBeginner = Color(0xFF00D9A0);

  // Border Colors
  static const Color border = Color(0xFF2D2D44);
  static const Color borderLight = Color(0xFF3A3A52);

  // Overlay Colors
  static Color overlay = Colors.black.withOpacity(0.5);
  static Color cardOverlay = Colors.black.withOpacity(0.3);

  // Match Percentage Colors
  static const Color matchHigh = Color(0xFF00D9A0);
  static const Color matchMedium = Color(0xFFFFA726);
  static const Color matchLow = Color(0xFFFF5252);
}
