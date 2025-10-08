import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/decorative_header.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<ExploreCategory> _categories = [
    ExploreCategory(
      title: 'Rüya Sembolleri',
      subtitle: 'Yaygın rüya sembollerini keşfet',
      icon: Icons.auto_awesome,
      color: const Color(0xFF6366F1),
      items: ['Su', 'Uçmak', 'Düşmek', 'Takip Edilmek', 'Sınav'],
    ),
    ExploreCategory(
      title: 'Ruh Halleri',
      subtitle: 'Rüyalardaki duygu durumları',
      icon: Icons.psychology,
      color: const Color(0xFF8B5CF6),
      items: ['Mutlu', 'Kaygılı', 'Huzurlu', 'Korkulu', 'Heyecanlı'],
    ),
    ExploreCategory(
      title: 'Rüya Tipleri',
      subtitle: 'Farklı rüya kategorileri',
      icon: Icons.category,
      color: const Color(0xFF10B981),
      items: ['Kabus', 'Lucid Rüya', 'Tekrarlayan', 'Peygamber', 'Renkli'],
    ),
    ExploreCategory(
      title: 'Kişiler',
      subtitle: 'Rüyalarda görülen kişiler',
      icon: Icons.people,
      color: const Color(0xFFF59E0B),
      items: ['Aile', 'Arkadaş', 'Yabancı', 'Ünlü', 'Tanıdık'],
    ),
    ExploreCategory(
      title: 'Mekanlar',
      subtitle: 'Rüya ortamları ve yerler',
      icon: Icons.location_on,
      color: const Color(0xFFEC4899),
      items: ['Ev', 'Okul', 'İş Yeri', 'Doğa', 'Bilinmeyen'],
    ),
    ExploreCategory(
      title: 'Hayvanlar',
      subtitle: 'Rüyalarda görülen hayvanlar',
      icon: Icons.pets,
      color: const Color(0xFF06B6D4),
      items: ['Köpek', 'Kedi', 'Kuş', 'Yılan', 'At'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Floating background clouds
          Positioned.fill(
            child: FloatingClouds(
              clouds: FloatingClouds.subtleClouds(theme),
            ),
          ),
          
          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
          // Modern Header
          SliverToBoxAdapter(
            child: DecorativeHeader(
              title: 'Keşfet',
              subtitle: 'Rüya sembollerini ve anlamlarını inceleyin',
              decorations: DecorativeHeader.starsDecorations(theme),
              minHeight: 160,
            ),
          ),
          
          // Gradient Transition
          const SliverToBoxAdapter(
            child: GradientTransition(),
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: _buildSearchBar(theme),
          ),
          
          // Categories Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return RepaintBoundary(
                    child: _buildCategoryCard(_categories[index], theme),
                  );
                },
                childCount: _categories.length,
              ),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Sembol veya kategori ara...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.search,
                color: theme.colorScheme.primary,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _showSearchResults(value);
            }
          },
        ),
      ),
    )
      .animate()
      .fadeIn(delay: 200.ms, duration: 400.ms)
      .slideY(begin: -0.2, end: 0);
  }

  Widget _buildCategoryCard(ExploreCategory category, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            _showCategoryDetails(category);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        category.color.withValues(alpha: 0.2),
                        category.color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 28,
                  ),
                ),
                
                const Spacer(),
                
                // Title
                Text(
                  category.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Subtitle
                Text(
                  category.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Items count with better styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        category.color.withValues(alpha: 0.15),
                        category.color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: category.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${category.items.length} öğe',
                        style: TextStyle(
                          fontSize: 11,
                          color: category.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(ExploreCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryDetailsSheet(category: category),
    );
  }

  void _showSearchResults(String query) {
    final snackBar = SnackBar(
      content: Text('Arama: "$query"'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class ExploreCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> items;

  ExploreCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class _CategoryDetailsSheet extends StatelessWidget {
  final ExploreCategory category;

  const _CategoryDetailsSheet({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: category.items.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: category.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(category.items[index]),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    onTap: () {
                      // TODO: Show item details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}