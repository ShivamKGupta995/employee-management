import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_dimensions.dart';

/// AppCard - Reusable card component with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final double borderRadius;
  final VoidCallback? onTap;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius = AppDimensions.radiusLG,
    this.onTap,
    this.border,
    this.boxShadow,
  }) : super(key: key);

  /// Standard card with default styling
  factory AppCard.standard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      padding: padding ?? AppDimensions.paddingCard,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  /// Elevated card with shadow
  factory AppCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      padding: padding ?? AppDimensions.paddingCard,
      margin: margin,
      boxShadow: AppDimensions.shadowMD,
      onTap: onTap,
      child: child,
    );
  }

  /// Outlined card with border
  factory AppCard.outlined({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return AppCard(
      padding: padding ?? AppDimensions.paddingCard,
      margin: margin,
      border: Border.all(color: borderColor ?? AppColors.border),
      onTap: onTap,
      child: child,
    );
  }

  /// Colored card with custom background
  factory AppCard.colored({
    required Widget child,
    required Color color,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      padding: padding ?? AppDimensions.paddingCard,
      margin: margin,
      color: color,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: boxShadow ?? AppDimensions.shadowSM,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// StatCard - Card displaying a statistic with icon
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: AppDimensions.paddingCard,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconLG),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppDimensions.font3XL,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontMD,
            ),
          ),
        ],
      ),
    );
  }
}

/// ActionCard - Card with icon and title for quick actions
class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: AppDimensions.iconXL),
          const SizedBox(height: AppDimensions.spaceSM),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppDimensions.fontMD,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
