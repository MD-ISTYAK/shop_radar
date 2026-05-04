import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';
import '../providers/data_saver_provider.dart';
import 'premium_widgets.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  final VoidCallback? onProfileTap;
  final VoidCallback? onVideoTap;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onDelete,
    this.onEdit,
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
      duration: const Duration(milliseconds: 600),
    );
    _heartAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimController);

    if (widget.post.mediaType == 'video' && widget.post.videoUrl.isNotEmpty) {
      _initVideo();
    }
  }

  void _initVideo() {
    final url = AppConstants.getImageUrl(widget.post.videoUrl);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _heartAnimController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (widget.onLike != null) widget.onLike!();
    setState(() => _showHeart = true);
    _heartAnimController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(post),
          _buildMedia(post),
          _buildActions(post),
          _buildDetails(post),
        ],
      ),
    );
  }

  Widget _buildHeader(PostModel post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onProfileTap,
            child: PremiumAvatar(imageUrl: post.displayProfilePic, size: 40),
          ),
          const SizedBox(width: 12),
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
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (post.accountType == 'shop') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  Text(
                    '${post.location} • ${post.timeAgo}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (post.userId == widget.currentUserId || post.shopId == widget.currentUserId)
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textLight),
              onPressed: () => _showOptions(context),
            ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Post', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                if (widget.onDelete != null) widget.onDelete!();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(PostModel post) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onTap: widget.onVideoTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _buildMediaContent(post),
              ),
              if (_showHeart)
                ScaleTransition(
                  scale: _heartAnim,
                  child: const Icon(Icons.favorite, size: 100, color: Colors.white),
                ),
              if (post.taggedProducts.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    borderRadius: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'View Products',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(PostModel post) {
    if (post.mediaType == 'video' && _videoController != null) {
      return VideoPlayer(_videoController!);
    }

    final images = post.images.isNotEmpty ? post.images : [post.mediaUrl];
    if (images.length > 1) {
      return Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: images.length,
            itemBuilder: (context, i) => CachedNetworkImage(
              imageUrl: AppConstants.getImageUrl(images[i]),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _imagePageController,
                count: images.length,
                effect: const ScrollingDotsEffect(
                  dotWidth: 6,
                  dotHeight: 6,
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: AppConstants.getImageUrl(images[0]),
      fit: BoxFit.cover,
    );
  }

  Widget _buildActions(PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ActionButton(
            icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: post.isLiked ? Colors.red : null,
            onTap: widget.onLike,
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: widget.onComment,
          ),
          _ActionButton(
            icon: Icons.send_outlined,
            onTap: widget.onShare,
          ),
          const Spacer(),
          _ActionButton(
            icon: post.isSavedByMe ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            color: post.isSavedByMe ? AppColors.primary : null,
            onTap: widget.onSave,
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(PostModel post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.likeCount > 0)
            Text(
              '${post.likeCount} likes',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
              children: [
                TextSpan(
                  text: '${post.username} ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: post.content),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.commentCount > 0) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: widget.onComment,
              child: Text(
                'View all ${post.commentCount} comments',
                style: GoogleFonts.inter(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(icon, color: color ?? AppColors.textPrimary, size: 26),
      ),
    );
  }
}






