import 'package:flutter/material.dart';
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

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home,
      label: 'Ana Sayfa',
    ),
    NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Keşfet',
    ),
    NavItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history,
      label: 'Geçmiş',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          HomeScreen(),
          ExploreScreen(),
          DreamHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Container(
              margin: EdgeInsets.only(bottom: bottomPadding + 85),
              child: ScaleTransition(
                scale: _fabAnimationController,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      _showRecordDreamBottomSheet(context);
                    },
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    child: const Icon(
                      Icons.mic_rounded,
                      size: 28,
                    ),
                  ),
                ),
              ).animate().scale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
              ).then().shimmer(
                duration: const Duration(milliseconds: 2000),
                color: Colors.white.withOpacity(0.4),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          bottom: bottomPadding + 16, 
          left: 20, 
          right: 20
        ),
        height: 75,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.04),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface.withOpacity(0.9),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = _currentIndex == index;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    child: Container(
                      height: 55,
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isActive 
                            ? theme.colorScheme.primary.withOpacity(0.12)
                            : Colors.transparent,
                        border: isActive 
                            ? Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isActive ? 4 : 0),
                            decoration: isActive 
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                  )
                                : null,
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.65),
                              size: isActive ? 24 : 22,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate(target: isActive ? 1.0 : 0.0)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                      ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
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

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : theme.colorScheme.primary)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: _isRecording ? _pulseController.value * 10 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 48,
                      color: Colors.white,
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
