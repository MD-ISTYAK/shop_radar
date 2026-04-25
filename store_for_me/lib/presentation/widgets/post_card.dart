import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';
import '../providers/data_saver_provider.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback? onSave;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onProfileTap;
  final VoidCallback? onVideoTap;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    this.onSave,
    this.onComment,
    this.onShare,
    this.onProfileTap,
    this.onVideoTap,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimController;
  late Animation<double> _heartAnim;
  bool _showHeart = false;
  final PageController _imagePageController = PageController();
  VideoPlayerController? _videoController;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartAnimController);

    if (widget.post.isReel && widget.post.videoUrl.isNotEmpty) {
      _initVideo();
    }
  }

  void _initVideo() {
    final url = widget.post.videoUrl.startsWith('http')
        ? widget.post.videoUrl
        : AppConstants.getImageUrl(widget.post.videoUrl);
    
    // Cloudinary optimization for video: q_auto, br_1m (limit bitrate)
    final optimizedUrl = url.contains('cloudinary') 
        ? url.replaceFirst('/upload/', '/upload/q_auto:low,br_1m/') 
        : url;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(optimizedUrl))
      ..initialize().then((_) {
        if (mounted) {
          _videoController!.setVolume(0);
          _videoController!.setLooping(true);
          // Auto-play disabled for data saving; require tap
          setState(() {});
        }
      });
  }

  String _getOptimizedUrl(String url, bool isDataSaver) {
    if (!url.contains('cloudinary')) return AppConstants.getImageUrl(url);
    
    final baseUrl = AppConstants.getImageUrl(url);
    final transformation = isDataSaver ? 'q_low,f_auto,w_400' : 'q_auto,f_auto,w_800';
    return baseUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _heartAnimController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (!widget.post.isLikedBy(widget.currentUserId)) {
      widget.onLike();
    }
    setState(() => _showHeart = true);
    _heartAnimController.reset();
    _heartAnimController.forward().then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          _buildHeader(post),
          // ─── Media ───
          if (post.hasMedia) _buildMedia(post),
          // ─── Actions ───
          _buildActions(post),
          // ─── Likes Count ───
          if (post.likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '${post.likeCount} ${post.likeCount == 1 ? 'like' : 'likes'}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          // ─── Caption ───
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: post.username,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: post.content,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // ─── View Comments ───
          if (post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: GestureDetector(
                onTap: widget.onComment,
                child: Text(
                  'View all ${post.commentCount} comments',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                ),
              ),
            ),
          // ─── Time ───
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Text(
              post.timeAgo,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PostModel post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                ),
                border: Border.all(color: Colors.transparent, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkShimmerBase : AppColors.shimmerBase),
                  backgroundImage: post.displayProfilePic.isNotEmpty
                      ? CachedNetworkImageProvider(post.displayProfilePic)
                      : null,
                  child: post.displayProfilePic.isEmpty
                      ? Icon(
                          post.accountType == 'shop' ? Icons.store : Icons.person,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (post.accountType == 'shop') ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, size: 14, color: AppColors.info),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(PostModel post) {
    final isDataSaver = ref.watch(dataSaverProvider);

    if ((post.isReel || post.mediaType == 'video')) {
      final isInitialized = _videoController != null && _videoController!.value.isInitialized;
      final isPlaying = isInitialized && _videoController!.value.isPlaying;
      
      return GestureDetector(
        onDoubleTap: _onDoubleTap,
        onTap: () {
          if (!isInitialized) return;
          setState(() {
            if (isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: isInitialized ? _videoController!.value.aspectRatio : 1,
              child: isInitialized 
                ? VideoPlayer(_videoController!)
                : (post.images.isNotEmpty 
                    ? CachedNetworkImage(imageUrl: _getOptimizedUrl(post.images[0], isDataSaver), fit: BoxFit.cover)
                    : Container(color: Theme.of(context).dividerColor.withAlpha(30))),
            ),
            // Play overlay if not playing
            if (!isPlaying)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
            // Mute/Unmute
            if (isPlaying)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                      _videoController!.setVolume(_isMuted ? 0 : 1.0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 18),
                  ),
                ),
              ),
            // Heart animation
            if (_showHeart)
              AnimatedBuilder(
                animation: _heartAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartAnim.value,
                    child: const Icon(Icons.favorite, size: 80, color: Colors.white),
                  );
                },
              ),
          ],
        ),
      );
    }

    final images = post.images.isNotEmpty ? post.images : (post.mediaUrl.isNotEmpty ? [post.mediaUrl] : <String>[]);

    if (images.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: images.length == 1
                ? CachedNetworkImage(
                    imageUrl: _getOptimizedUrl(images[0], isDataSaver),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _imagePageController,
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          return CachedNetworkImage(
                            imageUrl: _getOptimizedUrl(images[i], isDataSaver),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Theme.of(context).dividerColor.withAlpha(30)),
                            errorWidget: (_, __, ___) => Container(
                              color: Theme.of(context).dividerColor.withAlpha(30),
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _imagePageController,
                            count: images.length,
                            effect: WormEffect(
                              dotWidth: 6,
                              dotHeight: 6,
                              activeDotColor: AppColors.primary,
                              dotColor: Colors.white.withAlpha(150),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          // Heart animation overlay
          if (_showHeart)
            AnimatedBuilder(
              animation: _heartAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _heartAnim.value,
                  child: const Icon(Icons.favorite, size: 80, color: Colors.white),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActions(PostModel post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              post.isLikedBy(widget.currentUserId) ? Icons.favorite : Icons.favorite_border,
              color: post.isLikedBy(widget.currentUserId) ? AppColors.error : Theme.of(context).iconTheme.color,
              size: 26,
            ),
            onPressed: widget.onLike,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 23),
            onPressed: widget.onComment,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, size: 23),
            onPressed: widget.onShare,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              post.isSavedByMe ? Icons.bookmark : Icons.bookmark_border,
              size: 25,
            ),
            onPressed: widget.onSave,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}





