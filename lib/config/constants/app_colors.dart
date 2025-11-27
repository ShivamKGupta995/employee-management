import 'package:flutter/material.dart';

/// AppColors - Centralized color palette for the entire app
/// Usage: AppColors.primary, AppColors.success, etc.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ==========================================
  // PRIMARY COLORS
  // ==========================================
  static const Color primary = Color(0xFF1565C0);        // Blue 800
  static const Color primaryLight = Color(0xFF42A5F5);   // Blue 400
  static const Color primaryDark = Color(0xFF0D47A1);    // Blue 900
  
  // ==========================================
  // SECONDARY COLORS
  // ==========================================
  static const Color secondary = Color(0xFF26A69A);      // Teal 400
  static const Color secondaryLight = Color(0xFF80CBC4); // Teal 200
  static const Color secondaryDark = Color(0xFF00796B);  // Teal 700

  // ==========================================
  // STATUS COLORS
  // ==========================================
  static const Color success = Color(0xFF4CAF50);        // Green
  static const Color successLight = Color(0xFFE8F5E9);   // Green 50
  static const Color warning = Color(0xFFFFA726);        // Orange
  static const Color warningLight = Color(0xFFFFF3E0);   // Orange 50
  static const Color error = Color(0xFFE53935);          // Red
  static const Color errorLight = Color(0xFFFFEBEE);     // Red 50
  static const Color info = Color(0xFF2196F3);           // Blue
  static const Color infoLight = Color(0xFFE3F2FD);      // Blue 50

  // ==========================================
  // NEUTRAL COLORS
  // ==========================================
  static const Color background = Color(0xFFF5F5F5);     // Grey 100
  static const Color surface = Color(0xFFFFFFFF);        // White
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // ==========================================
  // TEXT COLORS
  // ==========================================
  static const Color textPrimary = Color(0xFF212121);    // Grey 900
  static const Color textSecondary = Color(0xFF757575);  // Grey 600
  static const Color textHint = Color(0xFFBDBDBD);       // Grey 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ==========================================
  // BORDER & DIVIDER
  // ==========================================
  static const Color border = Color(0xFFE0E0E0);         // Grey 300
  static const Color divider = Color(0xFFEEEEEE);        // Grey 200

  // ==========================================
  // GRADIENT PRESETS
  // ==========================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient loginGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1A1A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================
  // CATEGORY COLORS (for notifications)
  // ==========================================
  static const Color categoryGeneral = Color(0xFF2196F3);  // Blue
  static const Color categoryUrgent = Color(0xFFE53935);   // Red
  static const Color categoryHoliday = Color(0xFF4CAF50);  // Green
  static const Color categoryEvent = Color(0xFFFFA726);    // Orange
  static const Color categoryPolicy = Color(0xFF9C27B0);   // Purple

  // ==========================================
  // ROLE COLORS
  // ==========================================
  static const Color adminColor = Color(0xFF6A1B9A);       // Purple
  static const Color employeeColor = Color(0xFF1976D2);    // Blue

  // ==========================================
  // HELPER METHODS
  // ==========================================
  
  /// Get color for category type
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'urgent':
        return categoryUrgent;
      case 'holiday':
        return categoryHoliday;
      case 'event':
        return categoryEvent;
      case 'policy':
        return categoryPolicy;
      default:
        return categoryGeneral;
    }
  }

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
