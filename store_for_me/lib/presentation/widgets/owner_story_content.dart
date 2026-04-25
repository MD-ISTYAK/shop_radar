import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../providers/shop_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OwnerStoryContent extends ConsumerWidget {
  final ScrollController scrollController;
  const OwnerStoryContent({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Social & Content', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 8),
          Text('Engage with your followers and customers', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          const SizedBox(height: 24),
          
          _ActionTile(
            icon: Icons.post_add_rounded,
            title: 'Create Post',
            subtitle: 'Share updates, offers and photos',
            color: AppColors.accent,
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/create-post');
              if (result == true) {
                ref.read(shopProvider.notifier).fetchOwnerShop();
              }
            },
          ),
          _ActionTile(
            icon: Icons.auto_stories_rounded,
            title: 'Create Story',
            subtitle: 'Post a 24-hour disappearing story',
            color: AppColors.warning,
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/create-story');
              if (result == true) {
                ref.read(shopProvider.notifier).fetchOwnerShop();
              }
            },
          ),
          _ActionTile(
            icon: Icons.settings_suggest_rounded,
            title: 'Manage Content',
            subtitle: 'Edit or delete existing posts/stories',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/shop-management'),
          ),
          _ActionTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Customer Messages',
            subtitle: 'Reply to customer inquiries',
            color: AppColors.success,
            onTap: () => Navigator.pushNamed(context, '/chat-list'),
          ),
          
          SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withAlpha(50), AppColors.accent.withAlpha(20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent.withAlpha(50)),
            ),
            child: Column(
              children: [
                const Icon(Icons.insights_rounded, size: 48, color: AppColors.accent),
                SizedBox(height: 16),
                const Text(
                  'Grow Your Community',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Regular posts and stories help you stay connected with your customers and drive more sales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? Colors.transparent).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}








