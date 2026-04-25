import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';
import '../providers/social_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<StoryGroupModel> storyGroups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    this.initialGroupIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _groupPageController;
  late AnimationController _progressController;
  int _currentGroupIndex = 0;
  int _currentStoryIndex = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _groupPageController = PageController(initialPage: _currentGroupIndex);
    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener(_onProgressComplete);
    _startStory();
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressComplete);
    _progressController.dispose();
    _groupPageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  StoryGroupModel get _currentGroup => widget.storyGroups[_currentGroupIndex];
  StoryModel get _currentStory => _currentGroup.stories[_currentStoryIndex];

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _startStory() {
    _videoController?.dispose();
    _videoController = null;

    if (_currentStory.isVideo && _currentStory.displayMediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(_currentStory.displayMediaUrl),
      )..initialize().then((_) {
          if (mounted) {
            _videoController!.play();
            _progressController.duration = _videoController!.value.duration;
            _progressController.forward(from: 0);
            setState(() {});
          }
        });
    } else {
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward(from: 0);
    }

    // Mark as viewed
    ref.read(socialProvider.notifier).markStoryViewed(_currentStory.id);
  }

  void _nextStory() {
    if (_currentStoryIndex < _currentGroup.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startStory();
    } else if (_currentGroupIndex < widget.storyGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _groupPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startStory();
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = _currentGroup.stories.length - 1;
      });
      _groupPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _progressController.stop();
    _videoController?.pause();
  }

  void _onTapUp(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _previousStory();
    } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
      _nextStory();
    } else {
      // Resume
      _progressController.forward();
      _videoController?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _currentGroup;
    final story = _currentStory;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── Media ───
            if (story.isVideo && _videoController != null && _videoController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else if (!story.isVideo && story.displayMediaUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: story.displayMediaUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            // ─── Top overlay ───
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Progress bars
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Row(
                          children: List.generate(
                            group.stories.length,
                            (i) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: i < _currentStoryIndex
                                    ? LinearProgressIndicator(
                                        value: 1.0,
                                        backgroundColor: Colors.white30,
                                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                                        minHeight: 2.5,
                                        borderRadius: BorderRadius.circular(2),
                                      )
                                    : i == _currentStoryIndex
                                        ? AnimatedBuilder(
                                            animation: _progressController,
                                            builder: (_, __) => LinearProgressIndicator(
                                              value: _progressController.value,
                                              backgroundColor: Colors.white30,
                                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                                              minHeight: 2.5,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          )
                                        : LinearProgressIndicator(
                                            value: 0.0,
                                            backgroundColor: Colors.white30,
                                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                                            minHeight: 2.5,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // User info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkShimmerBase : AppColors.shimmerBase),
                              backgroundImage: group.displayProfilePic.isNotEmpty
                                  ? CachedNetworkImageProvider(group.displayProfilePic)
                                  : null,
                              child: group.displayProfilePic.isEmpty
                                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              group.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              story.createdAt.difference(DateTime.now()).abs().inHours < 1
                                  ? '${story.createdAt.difference(DateTime.now()).abs().inMinutes}m ago'
                                  : '${story.createdAt.difference(DateTime.now()).abs().inHours}h ago',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Caption overlay ───
            if (story.caption.isNotEmpty)
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Text(
                  story.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 15, shadows: [
                    Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black87),
                  ]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}





