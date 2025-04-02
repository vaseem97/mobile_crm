import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF5768E1);
  static const Color primaryLight = Color(0xFF8B9AFF);
  static const Color primaryDark = Color(0xFF2743AE);

  // Secondary colors
  static const Color secondary = Color(0xFF3ACCE1);
  static const Color secondaryLight = Color(0xFF82FFFF);
  static const Color secondaryDark = Color(0xFF009BAF);

  // Background colors
  static const Color background = Color(0xFFF9FAFF);
  static const Color cardBackground = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF9FAFF);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
