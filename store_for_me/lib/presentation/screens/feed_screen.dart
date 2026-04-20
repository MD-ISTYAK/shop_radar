import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_bubble.dart';
import '../widgets/comment_sheet.dart';
import 'story_viewer_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(socialProvider.notifier).fetchFeed();
      ref.read(socialProvider.notifier).fetchStories();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(socialProvider.notifier).loadMoreFeed();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialProvider);
    final auth = ref.watch(authProvider);
    final currentUserId = auth.user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(socialProvider.notifier).fetchFeed(),
            ref.read(socialProvider.notifier).fetchStories(),
          ]);
        },
        child: social.isLoading
            ? _buildShimmer()
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Stories
                  SliverToBoxAdapter(
                    child: Container(
                      height: 100,
                      color: AppColors.card,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        itemCount: social.stories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return StoryBubble(
                              group: StoryGroupModel(stories: const [], username: 'Your story'),
                              isAddStory: true,
                              onTap: () => Navigator.pushNamed(context, '/create-story'),
                            );
                          }
                          return StoryBubble(
                            group: social.stories[index - 1],
                            onTap: () => _openStoryViewer(social.stories, index - 1),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  // Posts
                  if (social.feed.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.dynamic_feed_outlined, size: 64, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            const Text('No posts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Follow people to see their posts', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == social.feed.length) {
                            return social.isLoadingMore
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : const SizedBox(height: 80);
                          }
                          final post = social.feed[index];
                          return PostCard(
                            post: post,
                            currentUserId: currentUserId,
                            onLike: () => ref.read(socialProvider.notifier).toggleLike(post.id),
                            onSave: () => ref.read(socialProvider.notifier).toggleSavePost(post.id),
                            onComment: () => _showComments(post),
                          );
                        },
                        childCount: social.feed.length + 1,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _openStoryViewer(List<StoryGroupModel> stories, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => StoryViewerScreen(
          storyGroups: stories,
          initialGroupIndex: index,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showComments(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(
        postId: post.id,
        initialComments: post.comments,
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                    const SizedBox(width: 10),
                    Container(width: 120, height: 14, color: Colors.white),
                  ],
                ),
              ),
              Container(width: double.infinity, height: 300, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
