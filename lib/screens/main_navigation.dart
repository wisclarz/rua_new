import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'dream_history_screen.dart';
import 'profile_screen.dart';
import 'add_dream_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _activeIndicatorController;
  late List<AnimationController> _itemControllers;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _activeIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _itemControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _activeIndicatorController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    final theme = Theme.of(context);
    
    return Scaffold(
      // ✅ DÜZELTME: Explicit background color eklendi
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        // ✅ DÜZELTME: PageView'ı Container içine aldık
        color: theme.colorScheme.surface,
        child: PageView(
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
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildModernBottomNavigationBar(context),
    );
  }

  Widget _buildModernBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 70.0; // ✅ Artırıldı: 65 -> 70
    
    return Container(
      height: navBarHeight + bottomPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: navBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  index: 0,
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.explore_rounded,
                  label: 'Keşfet',
                  index: 1,
                  theme: theme,
                ),
                const SizedBox(width: 56),
                _buildNavItem(
                  icon: Icons.history_rounded,
                  label: 'Geçmiş',
                  index: 2,
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  index: 3,
                  theme: theme,
                ),
              ],
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _itemControllers[index],
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_itemControllers[index].value * 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4), // ✅ Azaltıldı: 8 -> 4
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center, // ✅ Eklendi
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(6), // ✅ Azaltıldı: 8 -> 6
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 22, // ✅ Azaltıldı: 24 -> 22
                      ),
                    ).animate(
                      target: isSelected ? 1 : 0,
                    ).scaleXY(
                      begin: 1.0,
                      end: 1.1,
                      duration: 300.ms,
                      curve: Curves.easeInOut,
                    ),
                    const SizedBox(height: 2), // ✅ Azaltıldı: 4 -> 2
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 10, // ✅ Azaltıldı: default ~12 -> 10
                      ),
                      child: Text(
                        label,
                        maxLines: 1, // ✅ Eklendi
                        overflow: TextOverflow.ellipsis, // ✅ Eklendi
                      ),
                    ),
                    const SizedBox(height: 1), // ✅ Azaltıldı: 2 -> 1
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2, // ✅ Azaltıldı: 3 -> 2
                      width: isSelected ? 16 : 0, // ✅ Azaltıldı: 20 -> 16
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return FloatingActionButton(
      onPressed: () async {
        HapticFeedback.mediumImpact();
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const AddDreamScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              
              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      elevation: 8,
      backgroundColor: theme.colorScheme.primary,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_rounded, // ✅ DEĞIŞTI: add_rounded -> mic_rounded
          size: 28, // ✅ Biraz küçültüldü: 32 -> 28
          color: Colors.white,
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).scaleXY(
        begin: 1.0,
        end: 1.08,
        duration: 1500.ms,
        curve: Curves.easeInOut,
      ).shimmer(
        duration: 2000.ms,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}