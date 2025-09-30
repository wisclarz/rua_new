import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final double blurValue;
  final double opacityValue;
  final Border? border;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 10.0,
    this.color,
    this.blurValue = 15.0,
    this.opacityValue = 0.1,
    this.border,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      height: height, // double.infinity kaldırıldı
      margin: margin,
      constraints: height == null ? null : BoxConstraints(
        maxHeight: height == double.infinity ? double.infinity : height!,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? theme.colorScheme.surface.withValues(alpha: opacityValue),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}