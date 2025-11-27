import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_dimensions.dart';

/// AppAvatar - Reusable avatar component
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showOnlineIndicator;
  final bool isOnline;

  const AppAvatar({
    Key? key,
    this.imageUrl,
    this.name,
    this.size = AppDimensions.avatarMD,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  }) : super(key: key);

  /// Small avatar
  factory AppAvatar.small({String? imageUrl, String? name}) {
    return AppAvatar(
      imageUrl: imageUrl,
      name: name,
      size: AppDimensions.avatarSM,
    );
  }

  /// Large avatar
  factory AppAvatar.large({String? imageUrl, String? name}) {
    return AppAvatar(
      imageUrl: imageUrl,
      name: name,
      size: AppDimensions.avatarLG,
    );
  }

  /// Profile avatar (extra large)
  factory AppAvatar.profile({String? imageUrl, String? name, VoidCallback? onTap}) {
    return AppAvatar(
      imageUrl: imageUrl,
      name: name,
      size: AppDimensions.avatarProfile,
      onTap: onTap,
    );
  }

  String get _initials {
    if (name == null || name!.isEmpty) return 'U';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.primaryLight.withValues(alpha: 0.3),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                _initials,
                style: TextStyle(
                  color: textColor ?? AppColors.primary,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );

    if (showOnlineIndicator) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.textSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

/// AppBadge - Badge component for counts or status
class AppBadge extends StatelessWidget {
  final String? text;
  final int? count;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;
  final Widget? child;

  const AppBadge({
    Key? key,
    this.text,
    this.count,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
    this.child,
  }) : super(key: key);

  /// Count badge
  factory AppBadge.count(int count, {Widget? child}) {
    return AppBadge(
      count: count,
      backgroundColor: AppColors.error,
      child: child,
    );
  }

  /// Status badge
  factory AppBadge.status(String text, Color color) {
    return AppBadge(
      text: text,
      backgroundColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSM,
        vertical: AppDimensions.spaceXXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.error,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: Text(
        text ?? (count != null ? (count! > 99 ? '99+' : count.toString()) : ''),
        style: TextStyle(
          color: textColor ?? AppColors.textOnPrimary,
          fontSize: AppDimensions.fontXS,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (child != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          Positioned(
            right: -5,
            top: -5,
            child: badgeWidget,
          ),
        ],
      );
    }

    return badgeWidget;
  }
}

/// CategoryChip - Chip for displaying categories
class CategoryChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    Key? key,
    required this.label,
    this.color,
    this.icon,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceXS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(
            color: chipColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppDimensions.iconXS,
                color: isSelected ? AppColors.textOnPrimary : chipColor,
              ),
              const SizedBox(width: AppDimensions.spaceXS),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textOnPrimary : chipColor,
                fontSize: AppDimensions.fontSM,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
