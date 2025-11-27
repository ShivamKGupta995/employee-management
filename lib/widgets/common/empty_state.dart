import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_dimensions.dart';

/// EmptyState - Widget to display when there's no data
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
  }) : super(key: key);

  /// Empty notifications state
  factory EmptyState.notifications() {
    return const EmptyState(
      icon: Icons.notifications_off_outlined,
      title: 'No Notifications',
      subtitle: 'You\'re all caught up!',
    );
  }

  /// Empty data state
  factory EmptyState.noData({String? title, String? subtitle}) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: title ?? 'No Data Found',
      subtitle: subtitle ?? 'There\'s nothing here yet.',
    );
  }

  /// Empty search results
  factory EmptyState.searchResults({String? query}) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      subtitle: query != null ? 'No results for "$query"' : 'Try a different search term.',
    );
  }

  /// Error state with retry
  factory EmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      subtitle: message ?? 'Please try again later.',
      buttonText: onRetry != null ? 'Retry' : null,
      onButtonPressed: onRetry,
      iconColor: AppColors.error,
    );
  }

  /// Network error state
  factory EmptyState.networkError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off_outlined,
      title: 'No Connection',
      subtitle: 'Please check your internet connection.',
      buttonText: onRetry != null ? 'Retry' : null,
      onButtonPressed: onRetry,
      iconColor: AppColors.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space3XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textSecondary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppDimensions.icon5XL,
                color: iconColor ?? AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppDimensions.fontMD,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppDimensions.spaceXL),
              ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
