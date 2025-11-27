import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_dimensions.dart';

/// LoadingIndicator - Various loading indicator styles
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const LoadingIndicator({
    Key? key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
  }) : super(key: key);

  /// Small loading indicator
  factory LoadingIndicator.small({Color? color}) {
    return LoadingIndicator(size: 16, color: color);
  }

  /// Large loading indicator
  factory LoadingIndicator.large({Color? color}) {
    return LoadingIndicator(size: 40, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// LoadingOverlay - Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    Key? key,
    this.message,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.borderRadiusMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppDimensions.spaceLG),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontMD,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// LoadingPage - Centered loading indicator for full pages
class LoadingPage extends StatelessWidget {
  final String? message;

  const LoadingPage({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator.large(),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spaceLG),
              Text(
                message!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppDimensions.fontMD,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ShimmerLoading - Skeleton loading placeholder
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    Key? key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppDimensions.radiusSM,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
