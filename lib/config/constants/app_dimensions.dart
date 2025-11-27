import 'package:flutter/material.dart';

/// AppDimensions - Centralized spacing, sizes, and dimensions
/// Ensures consistent UI across the entire app
class AppDimensions {
  AppDimensions._();

  // ==========================================
  // SPACING (Padding & Margin)
  // ==========================================
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double space3XL = 32.0;
  static const double space4XL = 40.0;
  static const double space5XL = 48.0;

  // ==========================================
  // BORDER RADIUS
  // ==========================================
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 30.0;
  static const double radiusCircle = 100.0;

  // BorderRadius Objects
  static BorderRadius get borderRadiusSM => BorderRadius.circular(radiusSM);
  static BorderRadius get borderRadiusMD => BorderRadius.circular(radiusMD);
  static BorderRadius get borderRadiusLG => BorderRadius.circular(radiusLG);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusRound => BorderRadius.circular(radiusRound);

  // ==========================================
  // ICON SIZES
  // ==========================================
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 28.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 40.0;
  static const double icon3XL = 48.0;
  static const double icon4XL = 60.0;
  static const double icon5XL = 80.0;

  // ==========================================
  // FONT SIZES
  // ==========================================
  static const double fontXS = 10.0;
  static const double fontSM = 12.0;
  static const double fontMD = 14.0;
  static const double fontLG = 16.0;
  static const double fontXL = 18.0;
  static const double fontXXL = 20.0;
  static const double font3XL = 24.0;
  static const double font4XL = 28.0;
  static const double font5XL = 32.0;
  static const double fontDisplay = 40.0;

  // ==========================================
  // BUTTON SIZES
  // ==========================================
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 44.0;
  static const double buttonHeightLG = 50.0;
  static const double buttonHeightXL = 56.0;

  // ==========================================
  // AVATAR SIZES
  // ==========================================
  static const double avatarSM = 32.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 50.0;
  static const double avatarXL = 60.0;
  static const double avatarXXL = 80.0;
  static const double avatarProfile = 100.0;

  // ==========================================
  // CARD DIMENSIONS
  // ==========================================
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 4.0;

  // ==========================================
  // APP BAR
  // ==========================================
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;

  // ==========================================
  // BOTTOM NAV BAR
  // ==========================================
  static const double bottomNavHeight = 60.0;
  static const double bottomNavElevation = 10.0;

  // ==========================================
  // HEADER DIMENSIONS
  // ==========================================
  static const double headerPaddingTop = 60.0;
  static const double headerPaddingHorizontal = 20.0;
  static const double headerPaddingBottom = 30.0;

  // ==========================================
  // INPUT FIELD
  // ==========================================
  static const double inputHeight = 48.0;
  static const double inputBorderWidth = 1.0;

  // ==========================================
  // DRAWER
  // ==========================================
  static const double drawerWidth = 280.0;

  // ==========================================
  // DIALOG
  // ==========================================
  static const double dialogMaxWidth = 400.0;

  // ==========================================
  // CLOCK IN BUTTON
  // ==========================================
  static const double clockButtonSize = 150.0;

  // ==========================================
  // EDGE INSETS PRESETS
  // ==========================================
  static const EdgeInsets paddingAll = EdgeInsets.all(spaceLG);
  static const EdgeInsets paddingAllSM = EdgeInsets.all(spaceSM);
  static const EdgeInsets paddingAllMD = EdgeInsets.all(spaceMD);
  static const EdgeInsets paddingAllXL = EdgeInsets.all(spaceXL);
  
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: spaceLG);
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: spaceLG);
  
  static const EdgeInsets paddingCard = EdgeInsets.all(spaceLG);
  static const EdgeInsets paddingScreen = EdgeInsets.all(spaceXL);
  static const EdgeInsets paddingListItem = EdgeInsets.symmetric(horizontal: spaceLG, vertical: spaceSM);

  // ==========================================
  // BOX SHADOWS
  // ==========================================
  static List<BoxShadow> get shadowSM => [
    BoxShadow(
      color: Colors.grey.withValues(alpha: 0.05),
      blurRadius: 5,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> get shadowMD => [
    BoxShadow(
      color: Colors.grey.withValues(alpha: 0.1),
      blurRadius: 10,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get shadowLG => [
    BoxShadow(
      color: Colors.grey.withValues(alpha: 0.15),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get shadowCard => [
    BoxShadow(
      color: Colors.grey.withValues(alpha: 0.08),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}
