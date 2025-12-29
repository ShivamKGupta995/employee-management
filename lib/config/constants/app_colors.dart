import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); 

  // ==========================================
  // YOUR EXISTING VARIABLES (DO NOT REMOVE)
  // ==========================================
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF80CBC4);
  static const Color secondaryDark = Color(0xFF00796B);
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerLight = Color(0xFFFFCDD2);
  static const Color actionSalary = Color(0xFF9C27B0);
  static const Color actionHolidays = Color(0xFFE91E63);
  static const Color actionEvidence = Color(0xFFFFA726);
  static const Color actionLeave = Color(0xFF2196F3);
  static const Color actionEmergency = Color(0xFFF44336);
  static const Color star = Color(0xFFFFC107);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceDisabled = Color(0xFFEEEEEE);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
  static const Color categoryGeneral = Color(0xFF2196F3);
  static const Color categoryUrgent = Color(0xFFE53935);
  static const Color categoryHoliday = Color(0xFF4CAF50);
  static const Color categoryEvent = Color(0xFFFFA726);
  static const Color categoryPolicy = Color(0xFF9C27B0);
  static const Color adminColor = Color(0xFF6A1B9A);
  static const Color employeeColor = Color(0xFF1976D2);

  // ==========================================
  // NEW LUXURY THEME ADDITIONS
  // ==========================================
  static const Color luxGold = Color(0xFFC5A367);        // Muted Metallic Gold
  static const Color luxLightGold = Color(0xFFF1D18A);   // Bright Gold for gradients
  static const Color luxDarkGreen = Color(0xFF13211C);   // Deep Background Green
  static const Color luxAccentGreen = Color(0xFF1D322C); // Card/Input Fill Green
  static const Color luxCream = Color(0xFFF5F1E6);       // For the "Holiday" light cards

  static const LinearGradient luxGoldGradient = LinearGradient(
    colors: [luxLightGold, luxGold],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient luxBgGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [luxAccentGreen, luxDarkGreen],
  );

  // Existing helpers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'urgent': return categoryUrgent;
      case 'holiday': return categoryHoliday;
      case 'event': return categoryEvent;
      case 'policy': return categoryPolicy;
      default: return categoryGeneral;
    }
  }

  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}