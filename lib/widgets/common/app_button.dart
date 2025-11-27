import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_dimensions.dart';

/// AppButton - Reusable button component with multiple variants
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isText;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isText = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeightLG,
    this.borderRadius = AppDimensions.radiusMD,
  }) : super(key: key);

  /// Primary filled button
  factory AppButton.primary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
      backgroundColor: AppColors.primary,
      textColor: AppColors.textOnPrimary,
    );
  }

  /// Success (green) button
  factory AppButton.success({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.success,
      textColor: AppColors.textOnPrimary,
    );
  }

  /// Error/Danger (red) button
  factory AppButton.danger({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.error,
      textColor: AppColors.textOnPrimary,
    );
  }

  /// Outlined button
  factory AppButton.outlined({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    Color? borderColor,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: true,
      icon: icon,
      textColor: borderColor ?? AppColors.primary,
    );
  }

  /// Text button (no background)
  factory AppButton.text({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Color? textColor,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isText: true,
      icon: icon,
      textColor: textColor ?? AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isText) {
      return _buildTextButton();
    } else if (isOutlined) {
      return _buildOutlinedButton();
    } else {
      return _buildElevatedButton();
    }
  }

  Widget _buildElevatedButton() {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          side: BorderSide(color: textColor ?? AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppDimensions.iconSM, color: textColor),
            const SizedBox(width: AppDimensions.spaceXS),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor ?? AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? AppColors.textOnPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDimensions.iconMD),
          const SizedBox(width: AppDimensions.spaceSM),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppDimensions.fontLG,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: AppDimensions.fontLG,
      ),
    );
  }
}
