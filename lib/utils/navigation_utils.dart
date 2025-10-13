// lib/utils/navigation_utils.dart
// ⚡ Ultra-fast custom page transitions for 60fps performance

import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// ⚡ Creates a fast, smooth page route with fade + slide animation
/// This is MUCH faster than default MaterialPageRoute (120ms vs 300ms)
Route<T> createFastRoute<T>(Widget page, {bool fullscreenDialog = false}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: AppConstants.animationFast, // 120ms - super fast!
    reverseTransitionDuration: AppConstants.animationFast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Combined fade + slide for smooth transition
      const begin = Offset(0.0, 0.05); // Subtle upward slide
      const end = Offset.zero;
      const curve = Curves.easeOut;

      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      final offsetAnimation = animation.drive(tween);
      
      // Fade animation
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    },
  );
}

/// ⚡ Creates an instant fade-only route (even faster - 100ms)
/// Perfect for modals and overlays
Route<T> createInstantFadeRoute<T>(Widget page, {bool fullscreenDialog = false}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: const Duration(milliseconds: 100), // Ultra fast!
    reverseTransitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

/// ⚡ Creates a slide-from-bottom route (good for bottom sheets alternative)
Route<T> createSlideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: AppConstants.animationNormal, // 200ms
    reverseTransitionDuration: AppConstants.animationNormal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.1);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      final offsetAnimation = animation.drive(tween);
      
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    },
  );
}

/// ⚡ Extension method for easy navigation
extension FastNavigation on BuildContext {
  /// Fast push with optimized transition
  Future<T?> pushFast<T>(Widget page) {
    return Navigator.push<T>(this, createFastRoute<T>(page));
  }
  
  /// Instant fade push
  Future<T?> pushInstant<T>(Widget page) {
    return Navigator.push<T>(this, createInstantFadeRoute<T>(page));
  }
  
  /// Slide up push
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.push<T>(this, createSlideUpRoute<T>(page));
  }
  
  /// Fast replacement with optimized transition
  Future<T?> pushReplacementFast<T, TO>(Widget page) {
    return Navigator.pushReplacement<T, TO>(this, createFastRoute<T>(page));
  }
}

