// lib/screens/main_navigation.dart - Ultra-Optimized Navigation with Smooth Animations
// ⚡ Performance optimizations:
// - AnimatedSwitcher with fast fade+slide (200ms smooth transition)
// - RepaintBoundary for each screen (isolated rendering)
// - No FAB animation (removed continuous scale animation for better FPS)
// - Minimal rebuilds with optimized setState
// - Fast page transitions (120ms)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../utils/navigation_utils.dart';
import '../providers/dream_provider.dart';
import '../services/notification_service.dart';
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

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _pendingNotificationHandled = false; // ⚡ Flag to prevent double handling

  // Static screen list - created once with RepaintBoundary for performance
  static const List<Widget> _screens = [
    HomeScreen(),
    ExploreScreen(),
    DreamHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ⚡ Handle pending notification ONCE (uygulama kapalıyken tıklanmışsa)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pendingNotificationHandled) {
        debugPrint('📱 MainNavigation rendered, checking for pending notification...');
        NotificationService().handlePendingInitialMessage();
        _pendingNotificationHandled = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ⚡ REMOVED: loadDreams() çağrısı kaldırıldı
    // DreamProvider zaten Firestore stream ile otomatik yüklüyor
    // Double loading problemi çözüldü
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed');
      // Dreams zaten stream ile yükleniyor, ekstra çağrı gereksiz
    }
  }

  void _onTabTapped(int index) {
    if (!mounted || index == _currentIndex) return;

    HapticFeedback.lightImpact();

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      // ⚡ AnimatedSwitcher = Smooth directional slide + fade
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200), // Hızlı ve smooth!
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Yönlü kaydırma animasyonu (sağa/sola)
          final bool isMovingRight = _currentIndex > _previousIndex;
          final double slideDirection = isMovingRight ? 0.03 : -0.03;
          
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(slideDirection, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: RepaintBoundary(
          key: ValueKey<int>(_currentIndex), // Key önemli!
          child: _screens[_currentIndex],
        ),
      ),
      floatingActionButton: _OptimizedFAB(theme: theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _OptimizedBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        theme: theme,
      ),
    );
  }
}

/// ⚡ Ultra-Optimized FAB - NO animations for maximum FPS
class _OptimizedFAB extends StatelessWidget {
  final ThemeData theme;
  
  const _OptimizedFAB({required this.theme});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.fabSize,
      height: AppConstants.fabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8a15ff),
            Color(0xFF7412d8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // ⚡ Ultra-fast custom transition (120ms instead of 300ms)
          context.pushFast(const AddDreamScreen());
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.mic,
          size: AppConstants.fabIconSize,
          color: Colors.white,
        ),
      ),
    );
    // ⚡ Removed continuous scale animation - huge FPS improvement!
  }
}

/// Optimized bottom navigation bar
class _OptimizedBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final ThemeData theme;
  
  const _OptimizedBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: theme.bottomNavigationBarTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: AppConstants.elevationHigh,
      shadowColor: theme.shadowColor,
      height: AppConstants.navBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: AppConstants.spacingXS,
      ),
      notchMargin: AppConstants.spacingS,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left section
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Ana Sayfa',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: 'Keşfet',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  theme: theme,
                ),
              ],
            ),
          ),
          
          // Center spacing for FAB
          const SizedBox(width: 64),
          
          // Right section
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'Geçmiş',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  theme: theme,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted navigation item widget for better performance
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;
  final ThemeData theme;
  
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: theme.bottomNavigationBarTheme.selectedItemColor?.withOpacity(0.1),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXS,
              vertical: AppConstants.spacingXS,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with background indicator - ⚡ Optimized for 60fps
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120), // Even faster!
                  curve: Curves.easeOut,
                  width: 56,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? theme.bottomNavigationBarTheme.selectedItemColor?.withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 120),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        isActive ? activeIcon : icon,
                        key: ValueKey<bool>(isActive),
                        size: AppConstants.iconL,
                        color: isActive 
                            ? theme.bottomNavigationBarTheme.selectedItemColor
                            : theme.bottomNavigationBarTheme.unselectedItemColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 2),
                
                // Label - ⚡ Fast text transition
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: isActive ? 10 : 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive 
                        ? theme.bottomNavigationBarTheme.selectedItemColor
                        : theme.bottomNavigationBarTheme.unselectedItemColor,
                    height: 2,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}