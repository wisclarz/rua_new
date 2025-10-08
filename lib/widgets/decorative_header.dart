import 'package:flutter/material.dart';

/// Reusable decorative header widget with clouds and gradient
class DecorativeHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? child;
  final List<DecorationItem> decorations;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? padding;
  final double minHeight;

  const DecorativeHeader({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.decorations = const [],
    this.gradientColors,
    this.padding,
    this.minHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultGradient = [
      theme.colorScheme.primary.withValues(alpha: 0.15),
      theme.colorScheme.secondary.withValues(alpha: 0.08),
      theme.colorScheme.surface,
    ];

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding ?? const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? defaultGradient,
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements
          ...decorations.map((decoration) => Positioned(
                top: decoration.top,
                right: decoration.right,
                left: decoration.left,
                bottom: decoration.bottom,
                child: Icon(
                  decoration.icon,
                  size: decoration.size,
                  color: decoration.color ??
                      theme.colorScheme.primary.withOpacity(decoration.opacity),
                ),
              )),

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
              if (child != null) child!,
            ],
          ),
        ],
      ),
    );
  }

  /// Cloud decorations preset
  static List<DecorationItem> cloudDecorations(ThemeData theme) => [
        DecorationItem(
          icon: Icons.cloud,
          size: 80,
          top: 10,
          right: 20,
          opacity: 0.05,
        ),
        DecorationItem(
          icon: Icons.cloud,
          size: 60,
          top: 40,
          right: 100,
          opacity: 0.03,
        ),
        DecorationItem(
          icon: Icons.cloud,
          size: 50,
          top: 20,
          left: 10,
          opacity: 0.04,
          color: theme.colorScheme.secondary.withOpacity(0.04),
        ),
      ];

  /// Stars decorations preset
  static List<DecorationItem> starsDecorations(ThemeData theme) => [
        DecorationItem(
          icon: Icons.stars,
          size: 80,
          top: 30,
          right: 20,
          opacity: 0.1,
        ),
        DecorationItem(
          icon: Icons.auto_awesome,
          size: 40,
          top: 50,
          right: 120,
          opacity: 0.15,
          color: theme.colorScheme.secondary.withOpacity(0.15),
        ),
        DecorationItem(
          icon: Icons.star,
          size: 60,
          top: 80,
          left: 30,
          opacity: 0.08,
        ),
      ];
}

/// Decoration item for header
class DecorationItem {
  final IconData icon;
  final double size;
  final double? top;
  final double? right;
  final double? left;
  final double? bottom;
  final double opacity;
  final Color? color;

  const DecorationItem({
    required this.icon,
    required this.size,
    this.top,
    this.right,
    this.left,
    this.bottom,
    this.opacity = 0.1,
    this.color,
  });
}

/// Gradient transition widget for smooth header-body transition
class GradientTransition extends StatelessWidget {
  final double height;
  final Color? startColor;
  final Color? endColor;
  final bool useExtendedGradient;

  const GradientTransition({
    super.key,
    this.height = 60,
    this.startColor,
    this.endColor,
    this.useExtendedGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: useExtendedGradient
              ? [
                  startColor ?? theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.primary.withOpacity(0.04),
                  theme.colorScheme.primary.withOpacity(0.02),
                  theme.colorScheme.primary.withOpacity(0.01),
                  endColor ?? theme.scaffoldBackgroundColor,
                ]
              : [
                  startColor ?? theme.colorScheme.surface.withOpacity(0.0),
                  endColor ?? theme.scaffoldBackgroundColor,
                ],
          stops: useExtendedGradient
              ? [0.0, 0.3, 0.6, 0.85, 1.0]
              : null,
        ),
      ),
    );
  }
}

/// Floating decorative clouds for body sections
class FloatingClouds extends StatelessWidget {
  final List<CloudDecoration> clouds;

  const FloatingClouds({
    super.key,
    required this.clouds,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: clouds.map((cloud) {
        return Positioned(
          top: cloud.top,
          right: cloud.right,
          left: cloud.left,
          bottom: cloud.bottom,
          child: Icon(
            cloud.icon,
            size: cloud.size,
            color: cloud.color,
          ),
        );
      }).toList(),
    );
  }

  /// Preset for scattered clouds throughout the body
  static List<CloudDecoration> scatteredClouds(ThemeData theme) => [
        CloudDecoration(
          icon: Icons.cloud,
          size: 120,
          top: 100,
          right: -20,
          color: theme.colorScheme.primary.withOpacity(0.03),
        ),
        CloudDecoration(
          icon: Icons.cloud,
          size: 90,
          top: 300,
          left: -15,
          color: theme.colorScheme.secondary.withOpacity(0.025),
        ),
        CloudDecoration(
          icon: Icons.cloud,
          size: 100,
          top: 550,
          right: 10,
          color: theme.colorScheme.primary.withOpacity(0.02),
        ),
        CloudDecoration(
          icon: Icons.cloud,
          size: 80,
          top: 800,
          left: 20,
          color: theme.colorScheme.primary.withOpacity(0.025),
        ),
      ];

  /// Preset for subtle clouds
  static List<CloudDecoration> subtleClouds(ThemeData theme) => [
        CloudDecoration(
          icon: Icons.cloud,
          size: 100,
          top: 150,
          right: 0,
          color: theme.colorScheme.primary.withOpacity(0.02),
        ),
        CloudDecoration(
          icon: Icons.cloud,
          size: 80,
          top: 400,
          left: -10,
          color: theme.colorScheme.secondary.withOpacity(0.015),
        ),
      ];
}

/// Cloud decoration configuration
class CloudDecoration {
  final IconData icon;
  final double size;
  final double? top;
  final double? right;
  final double? left;
  final double? bottom;
  final Color color;

  const CloudDecoration({
    required this.icon,
    required this.size,
    this.top,
    this.right,
    this.left,
    this.bottom,
    required this.color,
  });
}

