import 'package:flutter/material.dart';
import 'dart:ui';
import '../config/app_constants.dart';

/// Optimized DreamyBackground with performance improvements:
/// - Static cloud positions (no recalculation on rebuild)
/// - Const constructors where possible
/// - Reduced opacity calculations
class DreamyBackground extends StatelessWidget {
  final Widget child;
  
  const DreamyBackground({
    super.key,
    required this.child,
  });

  // Static cloud positions - calculated once, reused forever
  static const List<CloudPosition> _cloudPositions = [
    CloudPosition(top: 0.05, left: 0.12, size: 160.0),
    CloudPosition(top: 0.18, right: 0.25, size: 140.0),
    CloudPosition(top: 0.28, left: 0.60, size: 180.0),
    CloudPosition(top: 0.35, right: 0.08, size: 150.0),
    CloudPosition(top: 0.42, left: 0.22, size: 170.0),
    CloudPosition(top: 0.55, right: 0.45, size: 165.0),
    CloudPosition(top: 0.62, left: 0.70, size: 155.0),
    CloudPosition(top: 0.72, right: 0.30, size: 145.0),
    CloudPosition(top: 0.15, left: 0.42, size: 135.0),
    CloudPosition(top: 0.82, left: 0.15, size: 160.0),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Gradient Background - const gradient
            _GradientBackground(isDark: isDark),
            
            // Cloud Images - Performance optimized
            ...List.generate(AppConstants.cloudCount, (index) {
              return _CloudImage(
                key: ValueKey('cloud_$index'),
                position: _cloudPositions[index],
                index: index,
                isDark: isDark,
                screenWidth: constraints.maxWidth,
                screenHeight: constraints.maxHeight,
              );
            }),
            
            // Content
            child,
          ],
        );
      },
    );
  }
}

/// Cloud position data class - immutable and const
class CloudPosition {
  final double top;
  final double? left;
  final double? right;
  final double size;
  
  const CloudPosition({
    required this.top,
    this.left,
    this.right,
    required this.size,
  });
}

/// Extracted gradient background for better performance
class _GradientBackground extends StatelessWidget {
  final bool isDark;
  
  const _GradientBackground({required this.isDark});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF0F0624),
                  Color(0xFF1A0F2E),
                  Color(0xFF1F152E),
                ]
              : const [
                  Color(0xFFF0E5F9),
                  Color(0xFFF5F0FA),
                  Color(0xFFFAF5FF),
                ],
        ),
      ),
    );
  }
}

/// Separate cloud widget for better performance and reusability
class _CloudImage extends StatelessWidget {
  final CloudPosition position;
  final int index;
  final bool isDark;
  final double screenWidth;
  final double screenHeight;
  
  const _CloudImage({
    super.key,
    required this.position,
    required this.index,
    required this.isDark,
    required this.screenWidth,
    required this.screenHeight,
  });
  
  @override
  Widget build(BuildContext context) {
    // Calculate opacity once
    final baseOpacity = isDark 
        ? AppConstants.cloudOpacityBaseDark 
        : AppConstants.cloudOpacityBaseLight;
    final opacity = baseOpacity - (index * AppConstants.cloudOpacityStep);
    
    return Positioned(
      top: screenHeight * position.top,
      left: position.left != null ? screenWidth * position.left! : null,
      right: position.right != null ? screenWidth * position.right! : null,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          'assets/images/cloud.png',
          width: position.size,
          height: position.size * 0.6,
          fit: BoxFit.contain,
          color: isDark 
              ? const Color(0xFF9B4DE0).withOpacity(0.35)
              : const Color(0xFFDDD6FE).withOpacity(0.45),
          colorBlendMode: BlendMode.modulate,
          // Performance optimization: cache the image
          cacheWidth: position.size.toInt(),
          cacheHeight: (position.size * 0.6).toInt(),
        ),
      ),
    );
  }
}

/// Modern glass card widget with performance optimizations:
/// - Const where possible
/// - Reduced opacity calculations
/// - Uses AppConstants
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppConstants.radiusXL,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final effectiveColor = color ?? 
        (isDark
            ? const Color(0xFF1F152E).withOpacity(0.7)
            : Colors.white.withOpacity(0.7));
    
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.5);
    
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : const Color(0xFF7f13ec).withOpacity(0.1);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: AppConstants.borderNormal,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppConstants.blurSigma,
            sigmaY: AppConstants.blurSigma,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppConstants.spacingXL),
            child: child,
          ),
        ),
      ),
    );
  }
}

