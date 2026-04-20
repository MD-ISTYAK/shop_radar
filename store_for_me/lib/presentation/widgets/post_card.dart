import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback? onSave;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onProfileTap;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    this.onSave,
    this.onComment,
    this.onShare,
    this.onProfileTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimController;
  late Animation<double> _heartAnim;
  bool _showHeart = false;
  final PageController _imagePageController = PageController();

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
  }

  @override
  void dispose() {
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
      color: AppColors.card,
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
              ),
            ),
          // ─── Time ───
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Text(
              post.timeAgo,
              style: TextStyle(color: AppColors.textLight, fontSize: 11),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                ),
                border: Border.all(color: Colors.transparent, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.shimmerBase,
                  backgroundImage: post.displayProfilePic.isNotEmpty
                      ? CachedNetworkImageProvider(post.displayProfilePic)
                      : null,
                  child: post.displayProfilePic.isEmpty
                      ? Icon(
                          post.accountType == 'shop' ? Icons.store : Icons.person,
                          size: 16,
                          color: AppColors.textLight,
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
                    imageUrl: AppConstants.getImageUrl(images[0]),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.shimmerBase,
                      child: const Icon(Icons.broken_image, size: 48, color: AppColors.textLight),
                    ),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _imagePageController,
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          return CachedNetworkImage(
                            imageUrl: AppConstants.getImageUrl(images[i]),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.shimmerBase,
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
              color: post.isLikedBy(widget.currentUserId) ? AppColors.error : AppColors.textPrimary,
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
