// lib/screens/main_navigation.dart - Optimized UX Navigation Bar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
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

class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    DreamHistoryScreen(),
    ProfileScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (!mounted || index == _currentIndex) return;
    
    HapticFeedback.lightImpact();
    
    // Trigger animation
    _animationController.forward(from: 0.0);
    
    setState(() {
      _currentIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (!mounted) return;
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      floatingActionButton: Container(
        width: 76,
        height: 76,
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
              color: const Color(0xFF7f13ec).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddDreamScreen(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.mic,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1F152E),
        elevation: 8,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left section
            Expanded(
              child: Row(
                
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    
                    activeIcon: Icons.home,
                    label: 'Ana Sayfa',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: 'Keşfet',
                    index: 1,
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
                  _buildNavItem(
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history,
                    label: 'Geçmiş',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profil',
                    index: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          splashColor: const Color(0xFF7f13ec).withOpacity(0.1),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with background indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 56,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFF7f13ec).withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        isActive ? activeIcon : icon,
                        key: ValueKey<bool>(isActive),
                        size: 22,
                        color: isActive 
                            ? const Color(0xFF7f13ec)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 2),
                
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: isActive ? 10 : 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive 
                        ? const Color(0xFF7f13ec)
                        : const Color(0xFF9CA3AF),
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