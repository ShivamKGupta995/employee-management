import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_dimensions.dart';

/// AppTextField - Reusable text input component
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final Color? fillColor;
  final bool isDense;

  const AppTextField({
    Key? key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.fillColor,
    this.isDense = false,
  }) : super(key: key);

  /// Email input field
  factory AppTextField.email({
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return AppTextField(
      controller: controller,
      label: 'Email',
      hint: 'Enter your email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? (value) {
        if (value == null || !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  /// Password input field
  factory AppTextField.password({
    TextEditingController? controller,
    bool obscureText = true,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      controller: controller,
      label: 'Password',
      hint: 'Enter your password',
      prefixIcon: Icons.lock_outline,
      obscureText: obscureText,
      suffix: suffix,
      validator: validator ?? (value) {
        if (value == null || value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  /// Phone number input field
  factory AppTextField.phone({
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      controller: controller,
      label: 'Phone',
      hint: 'Enter phone number',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: validator,
    );
  }

  /// Multi-line text area
  factory AppTextField.multiline({
    TextEditingController? controller,
    String? label,
    String? hint,
    int maxLines = 4,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      validator: validator,
    );
  }

  /// Number input field
  factory AppTextField.number({
    TextEditingController? controller,
    String? label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      prefixIcon: prefixIcon,
      keyboardType: TextInputType.number,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      style: const TextStyle(
        fontSize: AppDimensions.fontMD,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textSecondary, size: AppDimensions.iconMD)
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor ?? AppColors.surface,
        isDense: isDense,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
          vertical: isDense ? AppDimensions.spaceSM : AppDimensions.spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
