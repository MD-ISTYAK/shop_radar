import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/social_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_bubble.dart';
import '../widgets/comment_sheet.dart';
import 'story_viewer_screen.dart';
import 'reels_screen.dart';
import 'search_users_screen.dart';
import 'public_profile_screen.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _feedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(socialProvider.notifier).fetchFeed();
      ref.read(socialProvider.notifier).fetchStories();
      ref.read(socialProvider.notifier).fetchReels();
    });

    _feedScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_feedScrollController.position.pixels >=
        _feedScrollController.position.maxScrollExtent - 200) {
      ref.read(socialProvider.notifier).loadMoreFeed();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedScrollController.removeListener(_onScroll);
    _feedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.id ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Shop Radar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchUsersScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 24),
            onPressed: () => Navigator.pushNamed(context, '/chat-list'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined)),
            Tab(icon: Icon(Icons.play_circle_outline)),
            Tab(icon: Icon(Icons.person_outline)),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textLight,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          const ReelsScreen(),
          PublicProfileScreen(userId: currentUserId),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    final social = ref.watch(socialProvider);
    final auth = ref.watch(authProvider);
    final currentUserId = auth.user?.id ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(socialProvider.notifier).fetchFeed(),
          ref.read(socialProvider.notifier).fetchStories(),
        ]);
      },
      child: social.isLoading
          ? _buildShimmerFeed()
          : CustomScrollView(
              controller: _feedScrollController,
              slivers: [
                // ─── Stories Bar ───
                SliverToBoxAdapter(
                  child: _buildStoriesBar(social.stories),
                ),
                // ─── Divider ───
                const SliverToBoxAdapter(
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                // ─── Feed ───
                if (social.feed.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyFeed(),
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
                          onProfileTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(userId: post.userId),
                              ),
                            );
                          },
                          onVideoTap: () {
                            ref.read(socialProvider.notifier).setTargetReelId(post.id);
                            _tabController.animateTo(1);
                          },
                        );
                      },
                      childCount: social.feed.length + 1,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStoriesBar(List<StoryGroupModel> stories) {
    return Container(
      height: 100,
      color: AppColors.card,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: stories.length + 1, // +1 for "Add" button
        itemBuilder: (context, index) {
          if (index == 0) {
            return StoryBubble(
              group: StoryGroupModel(stories: const [], username: 'Your story'),
              isAddStory: true,
              onTap: () => Navigator.pushNamed(context, '/create-story'),
            );
          }
          final group = stories[index - 1];
          return StoryBubble(
            group: group,
            onTap: () => _openStoryViewer(stories, index - 1),
          );
        },
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

  Widget _buildExploreTab() {
    final social = ref.watch(socialProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(socialProvider.notifier).fetchExplore(),
      child: social.explore.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_outlined, size: 64, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  const Text('Explore', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'Discover posts from the community',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: social.explore.length,
              itemBuilder: (context, index) {
                final post = social.explore[index];
                final imageUrl = post.images.isNotEmpty
                    ? AppConstants.getImageUrl(post.images.first)
                    : post.mediaUrl.isNotEmpty
                        ? AppConstants.getImageUrl(post.mediaUrl)
                        : '';

                return GestureDetector(
                  onTap: () => _showComments(post),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isNotEmpty
                          ? Image(
                              image: CachedNetworkImageProvider(imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.shimmerBase,
                                child: Icon(Icons.image, color: AppColors.textLight),
                              ),
                            )
                          : Container(
                              color: AppColors.primary.withAlpha(30),
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: Text(
                                  post.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                      if (post.images.length > 1)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(Icons.collections, color: Colors.white, size: 16),
                        ),
                      if (post.isReel)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 18),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text(
            'Welcome to Shop Radar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow shops and people to see their posts',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(2);
              ref.read(socialProvider.notifier).fetchExplore();
            },
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Find people to follow'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerFeed() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // Header shimmer
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
              // Image shimmer
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.white,
              ),
              // Actions shimmer
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(width: 24, height: 24, color: Colors.white),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
