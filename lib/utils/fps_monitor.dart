// lib/utils/fps_monitor.dart
// ⚡ FPS Monitor - Tracks app performance in real-time

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

/// FPS Monitor widget - Shows real-time FPS counter
/// Only visible in DEBUG mode
class FPSMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const FPSMonitor({
    super.key,
    required this.child,
    this.enabled = false, // Default: disabled (production)
  });

  @override
  State<FPSMonitor> createState() => _FPSMonitorState();
}

class _FPSMonitorState extends State<FPSMonitor> {
  double _fps = 0.0;
  int _frameCount = 0;
  DateTime _lastUpdate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    
    if (widget.enabled) {
      // Start monitoring frame timings
      SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
    }
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    if (!mounted) return;
    
    _frameCount += timings.length;
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate);
    
    // Update FPS every 500ms
    if (elapsed.inMilliseconds >= 500) {
      final fps = (_frameCount * 1000) / elapsed.inMilliseconds;
      
      setState(() {
        _fps = fps;
        _frameCount = 0;
        _lastUpdate = now;
      });
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // FPS Counter overlay (only if enabled)
        if (widget.enabled)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getFPSColor(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFPSIcon(),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_fps.toStringAsFixed(0)} FPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getFPSColor() {
    if (_fps >= 55) {
      return Colors.green; // Excellent (60+ FPS)
    } else if (_fps >= 45) {
      return Colors.orange; // Good (45-54 FPS)
    } else if (_fps >= 30) {
      return Colors.red; // Poor (30-44 FPS)
    } else {
      return Colors.red.shade900; // Very Poor (<30 FPS)
    }
  }

  IconData _getFPSIcon() {
    if (_fps >= 55) {
      return Icons.check_circle;
    } else if (_fps >= 30) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }
}

/// Global FPS Monitor toggle
class FPSSettings {
  static bool _enabled = false;
  
  static bool get enabled => _enabled;
  
  static void enable() {
    _enabled = true;
  }
  
  static void disable() {
    _enabled = false;
  }
  
  static void toggle() {
    _enabled = !_enabled;
  }
}

/// Extension for easy FPS monitoring
extension FPSMonitorExtension on Widget {
  Widget withFPSMonitor({bool enabled = false}) {
    return FPSMonitor(
      enabled: enabled,
      child: this,
    );
  }
}

