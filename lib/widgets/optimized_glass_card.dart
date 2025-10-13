// lib/widgets/optimized_glass_card.dart
// Ultra-optimized glass card for 120 FPS performance

import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// Optimized glass card without BackdropFilter for 120 FPS
/// BackdropFilter is GPU-intensive and causes frame drops on high refresh rates
/// This version uses simple opacity and borders for glass effect
class OptimizedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;

  const OptimizedGlassCard({
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
    
    // Pre-calculated colors - no repeated calculations
    final effectiveColor = color ?? 
        (isDark
            ? const Color(0xFF1F152E).withOpacity(0.8)
            : Colors.white.withOpacity(0.85));
    
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.6);
    
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.25)
        : const Color(0xFF7f13ec).withOpacity(0.08);

    return RepaintBoundary(
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppConstants.spacingXL),
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
        child: child,
      ),
    );
  }
}

/// Cached version of OptimizedGlassCard for static content
/// Use this when the child never changes
class CachedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;

  const CachedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppConstants.radiusXL,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: OptimizedGlassCard(
        padding: padding,
        margin: margin,
        borderRadius: borderRadius,
        color: color,
        child: child,
      ),
    );
  }
}

