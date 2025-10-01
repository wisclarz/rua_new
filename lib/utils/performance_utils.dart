// lib/utils/performance_utils.dart
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' show FrameTiming;

class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();

  // FPS Tracking
  double _currentFPS = 60.0;
  bool _isLowPerformance = false;
  
  // Thresholds
  static const double lowFPSThreshold = 30.0;
  static const double mediumFPSThreshold = 45.0;
  
  double get currentFPS => _currentFPS;
  bool get isLowPerformance => _isLowPerformance;
  bool get isMediumPerformance => _currentFPS < mediumFPSThreshold && _currentFPS >= lowFPSThreshold;
  bool get isHighPerformance => _currentFPS >= mediumFPSThreshold;

  /// Initialize FPS monitoring
  void startMonitoring() {
    if (kReleaseMode) {
      // Production'da daha basit kontrol
      _detectDevicePerformance();
    } else {
      // Debug'da gerçek FPS tracking
      _startFPSTracking();
    }
  }

  /// Basit cihaz performans tespiti
  void _detectDevicePerformance() {
    try {
      // Flutter 3.x+ uyumlu erişim
      final view = SchedulerBinding.instance.platformDispatcher.views.first;
      final physicalSize = view.physicalSize;
      final devicePixelRatio = view.devicePixelRatio;
      
      // Logical width hesapla
      final logicalWidth = physicalSize.width / devicePixelRatio;
      
      // Basit heuristic: düşük çözünürlük = düşük performans
      if (logicalWidth < 360) {
        // Çok küçük ekran (eski/düşük cihazlar)
        _isLowPerformance = true;
        _currentFPS = 30.0;
      } else if (logicalWidth < 411) {
        // Orta ekran
        _isLowPerformance = false;
        _currentFPS = 45.0;
      } else {
        // Büyük ekran (modern cihazlar)
        _isLowPerformance = false;
        _currentFPS = 60.0;
      }
      
      debugPrint('📊 Device Performance: ${_currentFPS}fps (${_isLowPerformance ? "Low" : "High"})');
      debugPrint('📱 Screen: ${logicalWidth.toStringAsFixed(0)}dp, DPR: ${devicePixelRatio.toStringAsFixed(1)}');
    } catch (e) {
      debugPrint('⚠️ Performance detection error: $e');
      // Fallback: orta performans varsay
      _isLowPerformance = false;
      _currentFPS = 45.0;
    }
  }

  /// Gerçek FPS tracking (debug mode)
  void _startFPSTracking() {
    int frameCount = 0;
    DateTime lastTime = DateTime.now();
    
    try {
      SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
        frameCount += timings.length;
        
        final now = DateTime.now();
        final elapsed = now.difference(lastTime).inMilliseconds;
        
        // Her 1 saniyede bir FPS hesapla
        if (elapsed >= 1000) {
          _currentFPS = (frameCount / elapsed * 1000).clamp(0.0, 120.0);
          _isLowPerformance = _currentFPS < lowFPSThreshold;
          
          debugPrint('📊 Current FPS: ${_currentFPS.toStringAsFixed(1)}');
          
          frameCount = 0;
          lastTime = now;
        }
      });
      
      debugPrint('✅ FPS tracking started');
    } catch (e) {
      debugPrint('⚠️ FPS tracking error: $e');
      // Fallback
      _detectDevicePerformance();
    }
  }

  /// Performansa göre animasyon süresi döndür
  Duration getAnimationDuration(Duration baseDuration) {
    if (_isLowPerformance) {
      return baseDuration * 1.5; // Düşük FPS'de animasyonları yavaşlat
    } else if (isMediumPerformance) {
      return baseDuration * 1.2;
    }
    return baseDuration;
  }

  /// Performansa göre animasyon curve'ü döndür
  Curve getAnimationCurve() {
    if (_isLowPerformance) {
      return Curves.linear; // Düşük FPS'de basit curve
    }
    return Curves.easeOut; // Yüksek FPS'de smooth curve
  }

  /// Kompleks animasyon yapılmalı mı?
  bool shouldUseComplexAnimation() {
    return !_isLowPerformance;
  }

  /// Blur/glassmorphism efekti kullanılmalı mı?
  bool shouldUseBlurEffects() {
    return isHighPerformance;
  }

  /// Shadow yoğunluğu
  double getShadowBlurRadius() {
    if (_isLowPerformance) return 4.0;
    if (isMediumPerformance) return 6.0;
    return 10.0;
  }
}

/// Widget extension for performance-aware building
extension PerformanceAwareWidget on Widget {
  Widget withPerformanceOptimization() {
    return RepaintBoundary(child: this);
  }
}

/// List extension for batched builds
extension PerformanceAwareList<T> on List<T> {
  /// Performansa göre batch size döndür
  int getBatchSize() {
    final perf = PerformanceManager();
    if (perf.isLowPerformance) return 5;
    if (perf.isMediumPerformance) return 10;
    return 20;
  }
}

/// Animation Helper
class PerformanceAwareAnimation {
  static Duration getDuration(int milliseconds) {
    final perf = PerformanceManager();
    final baseDuration = Duration(milliseconds: milliseconds);
    return perf.getAnimationDuration(baseDuration);
  }

  static Curve getCurve() {
    return PerformanceManager().getAnimationCurve();
  }
}