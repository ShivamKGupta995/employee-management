import 'package:flutter/material.dart';
import '../config/constants/app_colors.dart';
import '../config/constants/app_dimensions.dart';

/// SnackbarHelper - Utility class for showing snackbars
class SnackbarHelper {
  SnackbarHelper._();

  /// Show a success snackbar (green)
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show an error snackbar (red)
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  /// Show a warning snackbar (orange)
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Show an info snackbar (blue)
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline,
    );
  }

  /// Show a simple snackbar (default styling)
  static void show(BuildContext context, String message) {
    _show(context, message);
  }

  /// Show a snackbar with action
  static void showWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        action: SnackBarAction(
          label: actionLabel,
          textColor: AppColors.textOnDark,
          onPressed: onAction,
        ),
      ),
    );
  }

  /// Internal method to show snackbar
  static void _show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textOnDark, size: AppDimensions.iconSM),
              const SizedBox(width: AppDimensions.spaceSM),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textOnDark),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        margin: const EdgeInsets.all(AppDimensions.spaceLG),
      ),
    );
  }

  /// Hide current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
