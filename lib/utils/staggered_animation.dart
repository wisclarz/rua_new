// lib/utils/staggered_animation.dart
// High-performance staggered animation utilities

import 'package:flutter/material.dart';

/// Lightweight staggered fade-in widget
/// Uses implicit animations for better performance
class StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;
  final Curve curve;

  const StaggeredFadeIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}

/// Lightweight staggered slide widget
class StaggeredSlide extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;
  final Offset begin;
  final Curve curve;

  const StaggeredSlide({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 400),
    this.begin = const Offset(0, 0.2),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredSlide> createState() => _StaggeredSlideState();
}

class _StaggeredSlideState extends State<StaggeredSlide> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : widget.begin,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}

/// Combined fade and slide for better performance
class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;
  final Offset begin;
  final Curve curve;

  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 350),
    this.begin = const Offset(0, 0.15),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Use microtask for better performance
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : widget.begin,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// Lightweight scale animation
class StaggeredScale extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;
  final double begin;
  final Curve curve;

  const StaggeredScale({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 350),
    this.begin = 0.8,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredScale> createState() => _StaggeredScaleState();
}

class _StaggeredScaleState extends State<StaggeredScale> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _visible ? 1.0 : widget.begin,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}

/// Combined fade and scale
class StaggeredFadeScale extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;
  final double begin;
  final Curve curve;

  const StaggeredFadeScale({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 350),
    this.begin = 0.8,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredFadeScale> createState() => _StaggeredFadeScaleState();
}

class _StaggeredFadeScaleState extends State<StaggeredFadeScale> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedScale(
        scale: _visible ? 1.0 : widget.begin,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

