import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(socialProvider.notifier).fetchFeed();
      ref.read(socialProvider.notifier).fetchStories();
      ref.read(socialProvider.notifier).fetchExplore();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Social Feed'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'Explore'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Following Feed
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(socialProvider.notifier).fetchFeed();
              await ref.read(socialProvider.notifier).fetchStories();
            },
            child: social.isLoading
                ? const LoadingIndicator()
                : social.feed.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.dynamic_feed_outlined,
                        title: 'No posts yet',
                        subtitle: 'Follow shops to see their posts here',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: social.feed.length,
                        itemBuilder: (context, index) {
                          final post = social.feed[index];
                          return _PostCard(
                            post: post,
                            currentUserId: auth.user?.id ?? '',
                            onLike: () => ref.read(socialProvider.notifier).toggleLike(post.id),
                            onComment: (text) => ref.read(socialProvider.notifier).addComment(post.id, text),
                          );
                        },
                      ),
          ),
          // Explore
          RefreshIndicator(
            onRefresh: () => ref.read(socialProvider.notifier).fetchExplore(),
            child: social.explore.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.explore_outlined,
                    title: 'Nothing to explore',
                    subtitle: 'Posts from all shops will appear here',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: social.explore.length,
                    itemBuilder: (context, index) {
                      final post = social.explore[index];
                      return _PostCard(
                        post: post,
                        currentUserId: auth.user?.id ?? '',
                        onLike: () => ref.read(socialProvider.notifier).toggleLike(post.id),
                        onComment: (text) => ref.read(socialProvider.notifier).addComment(post.id, text),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final dynamic post;
  final String currentUserId;
  final VoidCallback onLike;
  final Function(String) onComment;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final commentController = TextEditingController();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight.withAlpha(50),
                  child: post.shopLogo.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: AppConstants.getImageUrl(post.shopLogo),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.store, color: AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.store, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.shopName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        DateFormat.yMMMd().add_jm().format(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
            ),
          // Images
          if (post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: post.images.length,
                  itemBuilder: (context, i) {
                    return CachedNetworkImage(
                      imageUrl: AppConstants.getImageUrl(post.images[i]),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.shimmerBase,
                        child: const Icon(Icons.broken_image, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedBy(currentUserId) ? Icons.favorite : Icons.favorite_border,
                        color: post.isLikedBy(currentUserId) ? AppColors.error : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likesCount}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 4),
                Text('${post.commentsCount}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Comments
          if (post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: post.comments.take(2).map<Widget>((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(text: c.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: ' ${c.text}'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Add comment
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (commentController.text.trim().isNotEmpty) {
                      onComment(commentController.text.trim());
                      commentController.clear();
                    }
                  },
                  child: const Icon(Icons.send, color: AppColors.primary, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
