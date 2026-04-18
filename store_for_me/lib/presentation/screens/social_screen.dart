import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';
import '../providers/community_provider.dart';
import '../widgets/common_widgets.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(socialProvider.notifier).fetchFeed();
      ref.read(communityProvider.notifier).fetchQuestions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community', style: TextStyle(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: () => Navigator.pushNamed(context, '/create-post')),
          IconButton(icon: const Icon(Icons.chat_outlined), onPressed: () => Navigator.pushNamed(context, '/chat-list')),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Reels'),
            Tab(text: 'Q&A'),
            Tab(text: 'Check-ins'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          _buildReelsTab(),
          _buildQATab(),
          _buildCheckInsTab(),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    final socialState = ref.watch(socialProvider);

    if (socialState.isLoading) return const LoadingIndicator(message: 'Loading feed...');
    if (socialState.feed.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.dynamic_feed_outlined,
        title: 'No posts yet',
        subtitle: 'Follow shops to see their posts here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(socialProvider.notifier).fetchFeed(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: socialState.feed.length,
        itemBuilder: (context, index) {
          final post = socialState.feed[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withAlpha(25),
                        child: const Icon(Icons.store, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(post.timeAgo, style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (post.content.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(post.content, style: const TextStyle(fontSize: 14)),
                  ],
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      _buildPostAction(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        '${post.likeCount}',
                        post.isLiked ? AppColors.error : null,
                        () => ref.read(socialProvider.notifier).toggleLike(post.id),
                      ),
                      const SizedBox(width: 24),
                      _buildPostAction(Icons.chat_bubble_outline, '${post.commentCount}', null, () {}),
                      const SizedBox(width: 24),
                      _buildPostAction(Icons.share_outlined, 'Share', null, () {}),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label, Color? color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, color: color ?? AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReelsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(socialProvider.notifier).fetchFeed();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: AppColors.textLight),
              const SizedBox(height: 12),
              const Text('Shop Reels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Short videos from nearby shops', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/create-story'),
                icon: const Icon(Icons.add),
                label: const Text('Create Reel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQATab() {
    final communityState = ref.watch(communityProvider);

    return Column(
      children: [
        // Ask question button
        Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => _showAskQuestionDialog(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withAlpha(25),
                    child: const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Ask your local community...', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        // Questions list
        Expanded(
          child: communityState.isLoading
              ? const LoadingIndicator(message: 'Loading questions...')
              : communityState.questions.isEmpty
                  ? const EmptyStateWidget(icon: Icons.question_answer_outlined, title: 'No questions yet', subtitle: 'Be the first to ask!')
                  : RefreshIndicator(
                      onRefresh: () => ref.read(communityProvider.notifier).fetchQuestions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: communityState.questions.length,
                        itemBuilder: (context, index) {
                          final q = communityState.questions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.accent.withAlpha(25),
                                        child: Text(q.userName.isNotEmpty ? q.userName[0] : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(q.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      if (q.area.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text('• ${q.area}', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(q.text, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textLight),
                                      const SizedBox(width: 4),
                                      Text('${q.answerCount} answers', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                      const SizedBox(width: 16),
                                      Icon(Icons.visibility_outlined, size: 16, color: AppColors.textLight),
                                      const SizedBox(width: 4),
                                      Text('${q.viewCount} views', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCheckInsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(socialProvider.notifier).fetchFeed();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 64, color: AppColors.textLight),
              const SizedBox(height: 12),
              const Text('Check-Ins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Visit a shop and check in to earn points!', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAskQuestionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ask a Question'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g., Best salon near Lajpat Nagar?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(communityProvider.notifier).postQuestion(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
