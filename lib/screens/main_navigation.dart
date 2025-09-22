import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import 'dream_history_screen.dart';
import 'profile_screen.dart';
import 'explore_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late AnimationController _navAnimationController;
  late AnimationController _activeIndicatorController;
  
  // Animation controllers for each navigation item
  late List<AnimationController> _itemControllers;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _activeIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animation controllers for navigation items
    _itemControllers = List.generate(4, (index) => AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    ));
    
    _fabAnimationController.forward();
    _navAnimationController.forward();
    _activeIndicatorController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _navAnimationController.dispose();
    _activeIndicatorController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (!mounted) return;
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Trigger bounce animation for tapped item
    _itemControllers[index].forward().then((_) {
      _itemControllers[index].reverse();
    });
    
    // Reset active indicator animation
    _activeIndicatorController.reset();
    _activeIndicatorController.forward();
    
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (mounted) {
            // Use post-frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
          setState(() {
            _currentIndex = index;
          });
              }
            });
          }
        },
        children: const [
          HomeScreen(),
          ExploreScreen(),
          DreamHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildModernBottomNavigationBar(context),
    );
  }

  Widget _buildModernBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 65.0; // Reduced height to prevent overflow
    
    return Container(
      height: navBarHeight + bottomPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Enhanced Notch Cut
            Positioned.fill(
              child: CustomPaint(
                painter: ModernNotchPainter(
                  notchColor: theme.colorScheme.surface.withOpacity(0.95),
                  shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
                ),
              ),
            ),
            
            // Animated background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface.withOpacity(0.9),
                      theme.colorScheme.surface.withOpacity(0.95),
                    ],
                  ),
                ),
              ),
            ),
            
            // Navigation items with enhanced positioning
            Positioned(
              bottom: bottomPadding + 8,
              left: 0,
              right: 0,
              child: SizedBox(
                height: navBarHeight - 16, // Adjusted for reduced height
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEnhancedNavItem(context, 0, Icons.home_rounded, Icons.home_outlined, 'Ana Sayfa', theme.colorScheme.primary),
                      _buildEnhancedNavItem(context, 1, Icons.explore_rounded, Icons.explore_outlined, 'Keşfet', theme.colorScheme.secondary),
                      const SizedBox(width: 80), // Adjusted space for FAB
                      _buildEnhancedNavItem(context, 2, Icons.history_rounded, Icons.history_outlined, 'Geçmiş', theme.colorScheme.tertiary),
                      _buildEnhancedNavItem(context, 3, Icons.person_rounded, Icons.person_outline_rounded, 'Profil', Colors.orange),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 1,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    ).animate().shimmer(
      duration: const Duration(milliseconds: 1000),
      color: theme.colorScheme.primary.withOpacity(0.1),
    );
  }

  Widget _buildEnhancedNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isActive = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: AnimatedBuilder(
          animation: _itemControllers[index],
          builder: (context, child) {
            return Container(
              height: 50, // Reduced height to prevent overflow
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
                curve: Curves.easeInOutQuart,
                builder: (context, value, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enhanced Icon Container with morphing effect
                      Container(
                        width: 36,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.transparent,
                            color.withOpacity(0.12),
                            value,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: isActive 
                              ? Border.all(
                                  color: color.withOpacity(0.2 * value), 
                                  width: 1.2
                                )
                              : null,
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: color.withOpacity(0.25 * value),
                              blurRadius: 6 * value,
                              spreadRadius: 0,
                              offset: Offset(0, 2 * value),
                            ),
                          ] : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background pulse effect when active
                            if (isActive)
                              AnimatedBuilder(
                                animation: _activeIndicatorController,
                                builder: (context, child) {
                                  return Container(
                                    width: 36 * (1 + _activeIndicatorController.value * 0.2),
                                    height: 28 * (1 + _activeIndicatorController.value * 0.2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08 * (1 - _activeIndicatorController.value)),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  );
                                },
                              ),
                            
                            // Fixed Icon without rotation animation
                            Transform.scale(
                              scale: 1.0 + (0.1 * value) + (_itemControllers[index].value * 0.15),
                              child: Icon(
                                isActive ? activeIcon : inactiveIcon,
                                color: Color.lerp(
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                                  color,
                                  value,
                                ),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // Enhanced Text with better animations
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          style: TextStyle(
                            fontSize: 8.5 + (0.5 * value),
                            fontWeight: FontWeight.lerp(
                              FontWeight.w500,
                              FontWeight.w700,
                              value,
                            ),
                            color: Color.lerp(
                              theme.colorScheme.onSurface.withOpacity(0.7),
                              color,
                              value,
                            ),
                            letterSpacing: 0.1 + (0.1 * value),
                            height: 1.0,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Container(
          width: 75,
          height: 75,
          margin: const EdgeInsets.only(top: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom paint for notched circular button
              CustomPaint(
                size: const Size(75, 75),
                painter: NotchedCircularButtonPainter(
                  animation: _fabAnimationController,
                  primaryColor: theme.colorScheme.primary,
                  secondaryColor: theme.colorScheme.secondary,
                  shimmerProgress: _fabAnimationController.value,
                ),
              ),
              
              // Material for ripple effect
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _showRecordDreamBottomSheet(context);
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 75,
                    height: 75,
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: 1.0 + (_fabAnimationController.value * 0.08),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Icon shadow
                          Transform.translate(
                            offset: const Offset(1.5, 1.5),
                            child: Icon(
                              Icons.mic_rounded,
                              color: Colors.black.withOpacity(0.3),
                              size: 30,
                            ),
                          ),
                          // Main icon
                          Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          // Top highlight
                          Transform.translate(
                            offset: const Offset(-0.8, -0.8),
                            child: Icon(
                              Icons.mic_rounded,
                              color: Colors.white.withOpacity(0.4),
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Pulsing indicator dot
              Positioned(
                top: 12,
                child: AnimatedBuilder(
                  animation: _fabAnimationController,
                  builder: (context, child) {
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.8 + 0.2 * sin(_fabAnimationController.value * 3 * pi),
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(
        begin: const Offset(0.98, 0.98),
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeInOutSine,
      )
      .animate(onComplete: (controller) {
        controller.repeat(reverse: true);
      })
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: const Duration(milliseconds: 2200),
        curve: Curves.easeInOutCubic,
      );
  }

  void _showRecordDreamBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecordDreamBottomSheet(),
    );
  }
}

class ModernNotchPainter extends CustomPainter {
  final Color notchColor;
  final Color shadowColor;

  ModernNotchPainter({
    required this.notchColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = notchColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    final notchRadius = 42.0; // Enhanced radius for better cut
    final notchDepth = 12.0; // Deeper notch for better visual separation
    final notchCenter = size.width / 2;
    final notchStart = notchCenter - notchRadius;
    final notchEnd = notchCenter + notchRadius;

    // Start from top-left with enhanced rounded corner
    path.moveTo(0, 30);
    path.quadraticBezierTo(0, 0, 30, 0);

    // Draw to start of notch with smooth transition
    path.lineTo(notchStart - 10, 0);

    // Enhanced notch cut with multiple curves for smoother appearance
    path.quadraticBezierTo(notchStart - 5, 0, notchStart, 5);
    path.quadraticBezierTo(notchStart + 8, notchDepth, notchCenter - 15, notchDepth + 2);
    
    // Center curve of the notch
    path.quadraticBezierTo(notchCenter, notchDepth + 4, notchCenter + 15, notchDepth + 2);
    path.quadraticBezierTo(notchEnd - 8, notchDepth, notchEnd, 5);
    path.quadraticBezierTo(notchEnd + 5, 0, notchEnd + 10, 0);

    // Continue to top-right with enhanced rounded corner
    path.lineTo(size.width - 30, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 30);

    // Draw the sides and bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow first
    canvas.drawPath(path, shadowPaint);
    
    // Draw main shape
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ModernWavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color secondaryColor;

  ModernWavePainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.clipRRect(rect);

    final waveOffset = animation.value * size.width * 2;
    
    // Create wave patterns
    final path1 = Path();
    final path2 = Path();
    
    // First wave
    path1.moveTo(-size.width + waveOffset, size.height * 0.7);
    for (double x = -size.width + waveOffset; x <= size.width * 2 + waveOffset; x += 10) {
      final y = size.height * 0.7 + 
        15 * sin((x - waveOffset) * 0.02) * sin(animation.value * 2 * pi);
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width * 2 + waveOffset, size.height);
    path1.lineTo(-size.width + waveOffset, size.height);
    path1.close();

    // Second wave
    path2.moveTo(-size.width + waveOffset * 0.7, size.height * 0.4);
    for (double x = -size.width + waveOffset * 0.7; x <= size.width * 2 + waveOffset * 0.7; x += 8) {
      final y = size.height * 0.4 + 
        20 * sin((x - waveOffset * 0.7) * 0.015) * cos(animation.value * 1.5 * pi);
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width * 2 + waveOffset * 0.7, size.height);
    path2.lineTo(-size.width + waveOffset * 0.7, size.height);
    path2.close();

    // Draw waves
    canvas.drawPath(path1, Paint()..color = primaryColor);
    canvas.drawPath(path2, Paint()..color = secondaryColor);
  }

  @override
  bool shouldRepaint(ModernWavePainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}

class NotchedCircularButtonPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color secondaryColor;
  final double shimmerProgress;

  NotchedCircularButtonPainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.shimmerProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Create simple circular path
    final finalPath = Path();
    finalPath.addOval(Rect.fromCircle(center: center, radius: radius));

    // Main gradient
    final mainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(0.95),
          secondaryColor,
          primaryColor.withOpacity(0.85),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw main button shape
    canvas.drawPath(finalPath, mainPaint);

    // Add inner border for depth
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(finalPath, borderPaint);

    // Shimmer effect
    if (shimmerProgress > 0) {
      final shimmerWidth = size.width * 0.6;
      final shimmerX = -shimmerWidth + (size.width + shimmerWidth * 2) * shimmerProgress;
      
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(shimmerX, 0, shimmerWidth, size.height));

      canvas.save();
      canvas.clipPath(finalPath);
      canvas.translate(shimmerX, 0);
      canvas.skew(-0.3, 0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, shimmerWidth, size.height),
        shimmerPaint,
      );
      canvas.restore();
    }

    // Add highlight reflection
    final highlightPath = Path();
    highlightPath.addOval(Rect.fromLTWH(
      center.dx - radius * 0.7,
      center.dy - radius * 0.8,
      radius * 0.8,
      radius * 0.6,
    ));
    
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.save();
    canvas.clipPath(finalPath);
    canvas.drawPath(highlightPath, highlightPaint);
    canvas.restore();

    // Outer glow
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(finalPath, glowPaint);

    // Animated pulse ring
    final pulseRadius = radius * (1 + animation.value * 0.3);
    final pulsePaint = Paint()
      ..color = primaryColor.withOpacity(0.3 * (1 - animation.value))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(NotchedCircularButtonPainter oldDelegate) {
    return animation != oldDelegate.animation || 
           shimmerProgress != oldDelegate.shimmerProgress;
  }
}


class RecordDreamBottomSheet extends StatefulWidget {
  const RecordDreamBottomSheet({super.key});

  @override
  State<RecordDreamBottomSheet> createState() => _RecordDreamBottomSheetState();
}

class _RecordDreamBottomSheetState extends State<RecordDreamBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    
    if (_isRecording) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              _isRecording ? 'Rüyanızı Anlatın' : 'Rüya Kaydet',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _isRecording
                  ? 'Dinliyorum... Rüyanızı rahatça anlatabilirsiniz'
                  : 'Rüyanızı sesli olarak kaydetmek için mikrofon butonuna basın',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // Record Button
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isRecording 
                            ? [Colors.red.shade400, Colors.red.shade600]
                            : [theme.colorScheme.primary, theme.colorScheme.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : theme.colorScheme.primary)
                              .withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: _isRecording ? _pulseController.value * 15 : 5,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (_isRecording) ...[
              // Recording indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .then()
                    .fadeOut(duration: const Duration(milliseconds: 500)),
                  
                  const SizedBox(width: 8),
                  Text(
                    'Kayıt yapılıyor...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Cancel button
              TextButton(
                onPressed: () {
                  _toggleRecording();
                  Navigator.pop(context);
                },
                child: const Text('İptal'),
              ),
            ] else ...[
              // Tips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _buildTip(context, Icons.lightbulb_outline, 
                        'Rüyanızı olabildiğince detaylı anlatın'),
                    const SizedBox(height: 8),
                    _buildTip(context, Icons.volume_up_outlined, 
                        'Sessiz bir ortamda kayıt yapın'),
                    const SizedBox(height: 8),
                    _buildTip(context, Icons.timer_outlined, 
                        'Kayıt süresi 5 dakika ile sınırlıdır'),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
