import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glassmorphic_container.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<ExploreCategory> _categories = [
    ExploreCategory(
      title: 'Rüya Analizleri',
      subtitle: 'Popüler rüya yorumları',
      icon: Icons.psychology_outlined,
      color: const Color(0xFF6366F1),
      items: ['Uçma rüyaları', 'Su ile ilgili rüyalar', 'Hayvan rüyaları'],
    ),
    ExploreCategory(
      title: 'Ruh Sağlığı',
      subtitle: 'Uzman tavsiyeleri',
      icon: Icons.favorite_outline,
      color: const Color(0xFF10B981),
      items: ['Meditasyon teknikleri', 'Uyku hijyeni', 'Stres yönetimi'],
    ),
    ExploreCategory(
      title: 'Psikolog Bul',
      subtitle: 'Uzmanlarla iletişim',
      icon: Icons.person_search_outlined,
      color: const Color(0xFF8B5CF6),
      items: ['Online danışmanlık', 'Yakındaki uzmanlar', 'Randevu al'],
    ),
    ExploreCategory(
      title: 'Rüya Günlüğü',
      subtitle: 'İpuçları ve rehberlik',
      icon: Icons.book_outlined,
      color: const Color(0xFFF59E0B),
      items: ['Günlük tutma teknikleri', 'Rüya hatırlama', 'Sembol analizi'],
    ),
  ];

  void _showModernSnackBar(BuildContext context, String message, Color color, IconData icon) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 80,
            borderRadius: 16,
            blurValue: 20,
            color: color.withOpacity(0.8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate()
            .slideY(begin: -1.0, duration: const Duration(milliseconds: 500), curve: Curves.elasticOut)
            .fadeIn(duration: const Duration(milliseconds: 300)),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Keşfet',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.explore,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _categories[index];
                  return _buildCategoryCard(context, category, index);
                },
                childCount: _categories.length,
              ),
            ),
          ),
          
          // Featured Articles Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Öne Çıkan Makaleler',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturedArticle(
                    context,
                    'Rüyalarda Renklerin Anlamı',
                    'Rüyalarınızdaki renkler ne anlama geliyor?',
                    Icons.palette_outlined,
                    const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 12),
                  _buildFeaturedArticle(
                    context,
                    'Kabuslara Karşı Teknikler',
                    'Kötü rüyalarla başa çıkma yöntemleri',
                    Icons.shield_outlined,
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _buildFeaturedArticle(
                    context,
                    'Lüsid Rüya Nedir?',
                    'Rüyanızda kontrolü elinize alın',
                    Icons.lightbulb_outline,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ExploreCategory category, int index) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shadowColor: category.color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          _showCategoryDetails(context, category);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.color.withOpacity(0.1),
                category.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                category.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: category.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Keşfet',
                    style: TextStyle(
                      color: category.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideX(begin: 0.3, duration: const Duration(milliseconds: 600));
  }

  Widget _buildFeaturedArticle(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to article
          _showModernSnackBar(
            context,
            '$title makalesi yakında gelecek! 📖',
            Theme.of(context).colorScheme.primary,
            Icons.article,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 400))
      .slideX(begin: 0.2, duration: const Duration(milliseconds: 400));
  }

  void _showCategoryDetails(BuildContext context, ExploreCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryDetailsBottomSheet(category: category),
    );
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

class CategoryDetailsBottomSheet extends StatelessWidget {
  final ExploreCategory category;

  const CategoryDetailsBottomSheet({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          
          const SizedBox(height: 24),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: category.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = category.items[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        color: category.color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Daha fazla bilgi edinin',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: category.color,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$item yakında gelecek! 🔮'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      );
                    },
                  ),
                ).animate(delay: Duration(milliseconds: index * 100))
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .slideX(begin: 0.3, duration: const Duration(milliseconds: 400));
              },
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
