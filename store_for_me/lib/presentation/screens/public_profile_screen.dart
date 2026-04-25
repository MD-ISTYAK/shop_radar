import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/social_models.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/discover_people_row.dart';
import 'chat_screen.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Initial load will be handled by didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final socialState = ref.watch(socialProvider);
    // Trigger if new user OR missing data, and not already loading
    final isNewUser = socialState.lastLoadedProfileId != widget.userId;
    final isMissingData = socialState.viewingProfile == null;
    
    if (widget.userId.isNotEmpty && (isNewUser || isMissingData) && !socialState.isProfileLoading) {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId && widget.userId.isNotEmpty) {
      _loadData();
    }
  }

  void _loadData() {
    if (widget.userId.isEmpty) return;
    Future.microtask(() {
      if (mounted) {
        ref.read(socialProvider.notifier).loadFullProfile(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final socialState = ref.watch(socialProvider);
    final authState = ref.watch(authProvider);
    final profile = socialState.viewingProfile;
    final posts = socialState.profilePosts;
    final currentUserId = authState.user?.id ?? '';

    // Debugging print to see exactly why it enters error state
    debugPrint('PublicProfileScreen Build:');
    debugPrint(' - widget.userId: ${widget.userId}');
    debugPrint(' - profile.id: ${profile?.id}');
    debugPrint(' - isProfileLoading: ${socialState.isProfileLoading}');
    debugPrint(' - state.error: ${socialState.error}');
    debugPrint(' - lastLoadedProfileId: ${socialState.lastLoadedProfileId}');

    // 1. Loading State: If explicitly loading, or missing profile but not errored yet
    if (socialState.isProfileLoading || (profile == null && socialState.error == null)) {
      debugPrint(' -> Entering Loading State');
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Error State: Data load finished, but profile is missing or mismatched
    if (profile == null || profile.id != widget.userId) {
      debugPrint(' -> Entering Error State');
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  socialState.error ?? 'Failed to load profile', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final imagePosts = posts.where((p) => p.type != 'reel' && p.mediaType != 'video').toList();
    final reelPosts = posts.where((p) => p.type == 'reel' || p.mediaType == 'video').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(profile.username, style: const TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                  child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.card,
                        backgroundImage: profile.profilePicUrl.isNotEmpty
                            ? CachedNetworkImageProvider(profile.profilePicUrl)
                            : null,
                        child: profile.profilePicUrl.isEmpty
                            ? Icon(profile.isShop ? Icons.store : Icons.person, size: 40, color: AppColors.textLight)
                            : null,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(profile.postsCount.toString(), 'Posts'),
                            _buildStat(profile.followersCount.toString(), 'Followers'),
                            _buildStat(profile.followingCount.toString(), 'Following'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name.isNotEmpty ? profile.name : profile.username,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
                            ),
                            if (profile.bio.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                profile.bio, 
                                style: TextStyle(
                                  fontSize: 14, 
                                  color: AppColors.textPrimary.withAlpha(180),
                                  height: 1.4,
                                )
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (currentUserId != widget.userId)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // FIX: Pass both target and current user ID
                              final success = await ref.read(socialProvider.notifier).toggleFollow(widget.userId, currentUserId);
                              if (success) {
                                // Refreshing profile specifically is handled by optimistic update, but can reload
                                ref.read(socialProvider.notifier).loadFullProfile(widget.userId);
                                ref.read(socialProvider.notifier).fetchFeed();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: profile.isFollowing ? AppColors.card : AppColors.primary,
                              foregroundColor: profile.isFollowing ? AppColors.textPrimary : Colors.white,
                              side: profile.isFollowing ? const BorderSide(color: AppColors.divider) : BorderSide.none,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(profile.isFollowing ? 'Following' : 'Follow', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final ids = [currentUserId, widget.userId]..sort();
                              final conversationId = ids.join('_');
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId: conversationId,
                                    receiverId: widget.userId,
                                    shopId: null, // FIX: Direct DMs should have null shopId
                                    title: profile.username,
                                    otherUser: ChatUserModel(
                                      id: profile.id,
                                      name: profile.username,
                                      username: profile.username,
                                      profilePic: profile.profilePic,
                                    ),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.card,
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.divider),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (currentUserId == widget.userId) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Share logic
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.divider.withAlpha(150)),
                              foregroundColor: AppColors.textPrimary,
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Share profile', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: DiscoverPeopleRow(),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                indicatorColor: AppColors.textPrimary,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textLight,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.play_circle_outline)),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        children: [
          _buildGrid(imagePosts, profile, currentUserId),
          _buildGrid(reelPosts, profile, currentUserId),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildGrid(List<PostModel> gridPosts, UserProfileModel profile, String currentUserId) {
    if (gridPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(profile.isShop ? Icons.storefront : Icons.camera_alt_outlined, size: 60, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text('No Posts Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: gridPosts.length,
      itemBuilder: (context, index) {
        final post = gridPosts[index];
        final imageUrl = post.images.isNotEmpty ? post.images.first : (post.mediaUrl.isNotEmpty ? post.mediaUrl : '');
        return GestureDetector(
          onTap: () {
            // Can push a feed view zoomed into this post
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: AppColors.shimmerBase,
                child: (imageUrl.isNotEmpty && !post.isReel && post.mediaType != 'video')
                    ? CachedNetworkImage(
                        imageUrl: AppConstants.getImageUrl(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          (post.isReel || post.mediaType == 'video') ? Icons.videocam : Icons.broken_image,
                          color: AppColors.textLight,
                          size: 32,
                        ),
                      ),
              ),
              if (post.isReel || post.mediaType == 'video')
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              if (post.images.length > 1)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.collections, color: Colors.white, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
