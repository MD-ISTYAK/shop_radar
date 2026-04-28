import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';

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
  AudioPlayer? _audioPlayer;

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
    _audioPlayer?.dispose();
    super.dispose();
  }

  StoryGroupModel get _currentGroup => widget.storyGroups[_currentGroupIndex];
  StoryModel get _currentStory => _currentGroup.stories[_currentStoryIndex];

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _pauseStory() {
    _progressController.stop();
    _videoController?.pause();
    _audioPlayer?.pause();
  }

  void _resumeStory() {
    _progressController.forward();
    _videoController?.play();
    _audioPlayer?.resume();
  }

  void _startStory() {
    _videoController?.dispose();
    _videoController = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;

    final music = _currentStory.interactiveElements.firstWhere(
      (e) => e.type == 'music',
      orElse: () => InteractiveElement(type: '', x: 0, y: 0, scale: 0, rotation: 0, data: {}),
    );

    if (music.type == 'music') {
      _audioPlayer = AudioPlayer();
      final url = music.data['url']?.toString();
      if (url != null && url.isNotEmpty) {
        _audioPlayer?.play(UrlSource(url));
      }
    }

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
    _pauseStory();
  }

  void _onTapUp(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _previousStory();
    } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
      _nextStory();
    } else {
      _resumeStory();
    }
  }

  Widget _buildInteractiveSticker(InteractiveElement element) {
    IconData icon;
    Color color;
    switch (element.type) {
      case 'poll':
        icon = Icons.poll;
        color = Colors.cyan;
        break;
      case 'question':
        icon = Icons.help_outline;
        color = Colors.purple;
        break;
      case 'link':
        icon = Icons.link;
        color = Colors.blueAccent;
        break;
      case 'mention':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alternate_email, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(element.data['text'] ?? 'Mention', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
      case 'music':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(element.data['title'] ?? 'Song', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text(element.data['artist'] ?? 'Artist', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      default:
        icon = Icons.star;
        color = Colors.amber;
    }

    return GestureDetector(
      onTap: () {
        _pauseStory();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Interacted with ${element.type}')));
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _resumeStory();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              element.type.toUpperCase(),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
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

            // Interactive Elements Overlay
            if (story.interactiveElements.isNotEmpty)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: story.interactiveElements.map((element) {
                        return Positioned(
                          left: (element.x * constraints.maxWidth) - 60,
                          top: (element.y * constraints.maxHeight) - 25,
                          child: Transform.rotate(
                            angle: element.rotation,
                            child: Transform.scale(
                              scale: element.scale,
                              child: _buildInteractiveSticker(element),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

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
                            if (group.userId == ref.watch(authProvider).user?.id)
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onPressed: () {
                                  _progressController.stop();
                                  _videoController?.pause();
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('Delete Story', style: TextStyle(color: Colors.red)),
                                          onTap: () {
                                            Navigator.pop(context); // Close bottom sheet
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Story'),
                                                content: const Text('Are you sure you want to delete this story?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      ref.read(socialProvider.notifier).deleteStory(story.id);
                                                      Navigator.pop(this.context);
                                                    },
                                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      ],
                                    )
                                  ).then((_) {
                                    if (mounted) {
                                      _progressController.forward();
                                      _videoController?.play();
                                    }
                                  });
                                },
                              ),
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





