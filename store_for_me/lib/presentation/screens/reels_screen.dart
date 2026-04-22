import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';
import '../providers/data_saver_provider.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
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

  void _initController(int index, String url, {bool forceAutoplay = false}) {
    if (_controllers.containsKey(index)) return;
    if (url.isEmpty) return;

    final isDataSaver = ref.read(dataSaverProvider);
    final fullUrl = url.startsWith('http') ? url : AppConstants.getImageUrl(url);
    
    // Cloudinary optimization for reel: q_auto:low, br_1.5M (reels need slightly more bitrate than tiny feed videos)
    final optimizedUrl = fullUrl.contains('cloudinary') 
        ? fullUrl.replaceFirst('/upload/', '/upload/q_auto:low,br_1.5m/') 
        : fullUrl;

    final controller = VideoPlayerController.networkUrl(Uri.parse(optimizedUrl));
    _controllers[index] = controller;

    controller.initialize().then((_) {
      if (mounted) {
        controller.setLooping(true);
        // Autoplay if it's the current page AND either Data Saver is OFF or it's forced
        if (index == _currentPage && (!isDataSaver || forceAutoplay)) {
          controller.play();
        }
        setState(() {});
      }
    });
  }

  void _onPageChanged(int index) {
    // Pause the old controller
    _controllers[_currentPage]?.pause();

    _currentPage = index;

    final isDataSaver = ref.read(dataSaverProvider);
    // Play the new one only if Data Saver is OFF
    if (!isDataSaver) {
      _controllers[index]?.play();
    }

    // Preload next
    final reels = ref.read(socialProvider).reels;
    if (index + 1 < reels.length) {
      _initController(index + 1, reels[index + 1].videoUrl);
    }

    // Dispose controllers 2+ pages away
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
    if (reels.isNotEmpty) _initController(0, reels[0].videoUrl);
    if (reels.length > 1) _initController(1, reels[1].videoUrl);

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
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),

            // ─── Paused overlay ───
            if (controller?.value.isPlaying == false && controller?.value.isInitialized == true)
              const Center(
                child: Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white54),
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
                      backgroundColor: AppColors.shimmerBase,
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
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  // Share
                  _buildSideAction(
                    icon: Icons.send_outlined,
                    label: 'Share',
                    onTap: () {},
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
                          backgroundColor: AppColors.shimmerBase,
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
}
