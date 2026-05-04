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
import 'package:share_plus/share_plus.dart';
import '../widgets/share_to_dm_sheet.dart';
import '../widgets/premium_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

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
      ref.read(socialProvider.notifier).fetchSuggestedUsers();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Shop Radar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/snap-camera'),
          ),
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
          labelColor: isDark ? Colors.white : AppColors.textPrimary,
          unselectedLabelColor: AppColors.textLight,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          const ReelsScreen(),
          currentUserId.isEmpty 
            ? const Center(child: CircularProgressIndicator()) 
            : PublicProfileScreen(userId: currentUserId),
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
          : (social.feed.isEmpty && social.stories.isEmpty
              ? _buildEmptyFeed()
              : ListView.builder(
                  controller: _feedScrollController,
                  padding: EdgeInsets.zero,
                  itemCount: social.feed.length + 2, // stories + feed + loader
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildStoriesBar(social.stories);
                    }
                    if (index == social.feed.length + 1) {
                      return social.isLoadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : const SizedBox(height: 80);
                    }
                    return _buildPostCard(social.feed[index - 1], currentUserId);
                  },
                )),
    );
  }

  Widget _buildStoriesBar(List<StoryGroupModel> stories) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stories.length + 1,
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

  Widget _buildPostCard(PostModel post, String currentUserId) {
    return PostCard(
      post: post,
      currentUserId: currentUserId,
      onLike: () => ref.read(socialProvider.notifier).toggleLike(post.id),
      onSave: () => ref.read(socialProvider.notifier).toggleSavePost(post.id),
      onComment: () => _showComments(post),
      onShare: () => _handleSharePost(post),
      onDelete: () => _handleDeletePost(post),
      onEdit: (content) => _handleEditPost(post, content),
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
  }

  void _showComments(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(postId: post.id),
    );
  }

  void _handleSharePost(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareToDMSheet(post: post),
    );
  }

  void _handleDeletePost(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(socialProvider.notifier).deletePost(post.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Post deleted' : 'Failed to delete post'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleEditPost(PostModel post, String currentContent) {
    final TextEditingController controller = TextEditingController(text: currentContent);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Caption',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write something...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newContent = controller.text.trim();
                Navigator.pop(context);
                final success = await ref.read(socialProvider.notifier).updatePost(post.id, newContent);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Post updated' : 'Failed to update post')),
                  );
                }
              },
              child: const Text('Update Post'),
            ),
            const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildEmptyFeed() {
    final social = ref.watch(socialProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            social.error != null ? Icons.error_outline : Icons.feed_outlined,
            size: 64,
            color: social.error != null ? AppColors.error : AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            social.error ?? 'No posts yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (social.error == null)
            const Text('Follow some users to see their posts here', style: TextStyle(color: AppColors.textLight)),
          if (social.error != null)
            TextButton(
              onPressed: () => ref.read(socialProvider.notifier).fetchFeed(),
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerFeed() {
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 400,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
