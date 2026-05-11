import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:store_for_me/core/constants/app_constants.dart';
import 'package:store_for_me/core/theme/app_theme.dart';
import 'package:store_for_me/presentation/providers/social_provider.dart';
import 'package:store_for_me/presentation/providers/data_saver_provider.dart';
import 'package:store_for_me/presentation/widgets/comment_sheet.dart';
import 'package:store_for_me/presentation/widgets/share_to_dm_sheet.dart';
import 'package:store_for_me/data/models/social_models.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
  final VideoCacheManager _cacheManager = VideoCacheManager();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(socialProvider.notifier).fetchReels());
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Get the optimized remote URL for a reel video
  String _getVideoUrl(String url) {
    final fullUrl = url.startsWith('http') ? url : AppConstants.getImageUrl(url);
    // Cloudinary optimization: lower quality & bitrate for bandwidth savings
    return fullUrl.contains('cloudinary')
        ? fullUrl.replaceFirst('/upload/', '/upload/q_auto:low,br_1.5m/')
        : fullUrl;
  }

  /// Initialize a video controller for the given index.
  /// First checks local cache, then downloads and caches if needed.
  void _initController(int index, String rawUrl, String videoId, {bool forceAutoplay = false}) {
    if (_controllers.containsKey(index)) return;
    if (rawUrl.isEmpty) return;

    final isDataSaver = ref.read(dataSaverProvider);
    final optimizedUrl = _getVideoUrl(rawUrl);

    // Try to use cached version first, fall back to network
    _cacheManager.getCachedVideo(optimizedUrl, videoId).then((cachedPath) {
      if (!mounted) return;

      VideoPlayerController controller;
      if (cachedPath != null) {
        // Play from local disk (zero network!)
        controller = VideoPlayerController.file(
          File(cachedPath),
        );
      } else {
        // Fallback to network streaming
        controller = VideoPlayerController.networkUrl(Uri.parse(optimizedUrl));
      }

      _controllers[index] = controller;

      controller.initialize().then((_) {
        if (mounted) {
          controller.setLooping(true);
          if (index == _currentPage && (!isDataSaver || forceAutoplay)) {
            controller.play();
          }
          setState(() {});
        }
      });
    });
  }

  void _onPageChanged(int index) {
    // Pause the old controller
    _controllers[_currentPage]?.pause();

    _currentPage = index;

    final isDataSaver = ref.read(dataSaverProvider);
    if (!isDataSaver) {
      _controllers[index]?.play();
    }

    // Preload next reel
    final reels = ref.read(socialProvider).reels;
    if (index + 1 < reels.length) {
      _initController(index + 1, reels[index + 1].videoUrl, reels[index + 1].id);
    }

    // Prefetch next 2-3 videos into cache (background download)
    final prefetchList = <MapEntry<String, String>>[];
    for (int i = index + 2; i <= index + 4 && i < reels.length; i++) {
      final url = _getVideoUrl(reels[i].videoUrl);
      if (url.isNotEmpty) {
        prefetchList.add(MapEntry(url, reels[i].id));
      }
    }
    if (prefetchList.isNotEmpty) {
      _cacheManager.prefetch(prefetchList);
    }

    // Dispose controllers 2+ pages away to save memory
    final keysToRemove = _controllers.keys
        .where((k) => (k - index).abs() > 2)
        .toList();
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }

    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final socialState = ref.watch(socialProvider);
    final isDataSaver = ref.watch(dataSaverProvider);
    final reels = socialState.reels;

    ref.listen<String?>(
      socialProvider.select((s) => s.targetReelId),
      (previous, next) {
        if (next != null) {
          final reels = ref.read(socialProvider).reels;
          final idx = reels.indexWhere((r) => r.id == next);
          if (idx != -1 && _pageController.hasClients) {
            _pageController.jumpToPage(idx);
          }
          Future.microtask(() => ref.read(socialProvider.notifier).setTargetReelId(null));
        }
      },
    );

    if (reels.isEmpty) {
      return _buildEmptyState();
    }

    // Init first and second controllers
    if (reels.isNotEmpty) _initController(0, reels[0].videoUrl, reels[0].id);
    if (reels.length > 1) _initController(1, reels[1].videoUrl, reels[1].id);

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: reels.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final reel = reels[index];
        final controller = _controllers[index];

        return Stack(
          fit: StackFit.expand,
          children: [
            // ─── Video ───
            Container(
              color: Colors.black,
              child: controller != null && controller.value.isInitialized
                  ? GestureDetector(
                      onDoubleTap: () => ref.read(socialProvider.notifier).toggleReelLike(reel.id),
                      onTap: () {
                        setState(() {
                          controller.value.isPlaying ? controller.pause() : controller.play();
                        });
                      },
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    )
                  : reel.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _getOptimizedThumb(reel.thumbnailUrl, isDataSaver),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(child: CircularProgressIndicator(color: Colors.white)),
                        )
                      : Center(child: CircularProgressIndicator(color: Colors.white)),
            ),

            // ─── Paused overlay ───
            if (controller?.value.isPlaying == false && controller?.value.isInitialized == true)
              const Center(
                child: Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white54),
              ),

            // ─── Cache indicator (subtle) ───
            if (_cacheManager.isCached(_getVideoUrl(reel.videoUrl)))
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_done_rounded, size: 12, color: Colors.white60),
                      SizedBox(width: 3),
                      Text('Cached', style: TextStyle(color: Colors.white60, fontSize: 9)),
                    ],
                  ),
                ),
              ),

            // ─── Right side actions ───
            Positioned(
              right: 12,
              bottom: 120,
              child: Column(
                children: [
                  // Profile
                  _buildSideAction(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkShimmerBase : AppColors.shimmerBase),
                      backgroundImage: reel.profilePic.isNotEmpty
                          ? CachedNetworkImageProvider(AppConstants.getImageUrl(reel.profilePic))
                          : null,
                      child: reel.profilePic.isEmpty
                          ? const Icon(Icons.person, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Like
                  _buildSideAction(
                    icon: reel.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    label: _formatCount(reel.likesCount),
                    color: reel.isLikedByMe ? AppColors.error : Colors.white,
                    onTap: () => ref.read(socialProvider.notifier).toggleReelLike(reel.id),
                  ),
                  const SizedBox(height: 16),
                  // Comment
                  _buildSideAction(
                    icon: Icons.chat_bubble_outline,
                    label: _formatCount(reel.commentsCount),
                    onTap: () => _showComments(reel.id),
                  ),
                  const SizedBox(height: 16),
                  // Share
                  _buildSideAction(
                    icon: Icons.send_outlined,
                    label: 'Share',
                    onTap: () => _showShareToDM(reel),
                  ),
                ],
              ),
            ),

            // ─── Bottom info ───
            Positioned(
              left: 12,
              right: 60,
              bottom: 40,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkShimmerBase : AppColors.shimmerBase),
                          backgroundImage: reel.profilePic.isNotEmpty
                              ? CachedNetworkImageProvider(AppConstants.getImageUrl(reel.profilePic))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reel.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (reel.caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        reel.caption,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReelOptions(BuildContext context, WidgetRef ref, dynamic reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flag_rounded, color: AppColors.error, size: 22),
                  ),
                  title: Text(
                    'Report',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Report this reel for policy violation',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ReportDialog.show(
                      context,
                      targetId: reel.id,
                      targetType: 'reel',
                      onReported: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thanks for reporting. We\'ll review this content.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white10 : Colors.grey[100]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.visibility_off_outlined,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Not Interested',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'See fewer reels like this',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textLight,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getOptimizedThumb(String url, bool isDataSaver) {
    if (!url.contains('cloudinary')) return AppConstants.getImageUrl(url);
    final baseUrl = AppConstants.getImageUrl(url);
    final transformation = isDataSaver ? 'q_low,f_auto,w_400' : 'q_auto,f_auto,w_800';
    return baseUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }

  Widget _buildSideAction({
    IconData? icon,
    String? label,
    Color color = Colors.white,
    VoidCallback? onTap,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          if (child != null)
            child
          else
            Icon(icon, size: 28, color: color),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            const Text(
              'No Reels Yet',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Follow people to see their reels here',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showComments(String reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(
        postId: reelId,
        initialComments: const [], // Will fetch from API
      ),
    );
  }

  void _showShareToDM(ReelModel reel) {
    // Map Reel to PostModel for the Share Sheet
    final post = PostModel(
      id: reel.id,
      userId: reel.userId,
      username: reel.username,
      profilePic: reel.profilePic,
      content: reel.caption,
      videoUrl: reel.videoUrl,
      type: 'reel',
      createdAt: reel.createdAt,
    );
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareToDMSheet(post: post),
    );
  }
}





