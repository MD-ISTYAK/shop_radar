import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:store_for_me/core/theme/app_theme.dart';
import 'package:store_for_me/presentation/providers/social_provider.dart';
import 'package:dio/dio.dart';
import 'package:store_for_me/presentation/widgets/stickers/sticker_tools_panel.dart';
import 'package:store_for_me/presentation/widgets/stickers/interactive_sticker_canvas.dart';
import 'package:store_for_me/presentation/widgets/stickers/music_picker_sheet.dart';
import 'package:store_for_me/data/models/social_models.dart';

class SnapPreviewScreen extends ConsumerStatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final List<double> filter;
  final String filterName;

  const SnapPreviewScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    required this.filter,
    required this.filterName,
  });

  @override
  ConsumerState<SnapPreviewScreen> createState() => _SnapPreviewScreenState();
}

class _SnapPreviewScreenState extends ConsumerState<SnapPreviewScreen> {
  final List<OverlayText> _overlays = [];
  final GlobalKey _repaintKey = GlobalKey();
  VideoPlayerController? _videoController;
  bool _isSaving = false;
  final GlobalKey<InteractiveStickerCanvasState> _canvasKey = GlobalKey();
  List<StickerData> _stickers = [];
  PostMusic? _music;
  final editorKey = GlobalKey<ProImageEditorState>();

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          _videoController!.play();
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _postEditedImage(Uint8List bytes) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final directory = await getTemporaryDirectory();
      final editedPath = '${directory.path}/edited_snap_${DateTime.now().millisecondsSinceEpoch}.jpg';
      File imgFile = File(editedPath);
      await imgFile.writeAsBytes(bytes);

      // Automatically save to gallery
      try {
        await Gal.putImage(imgFile.path);
      } catch (e) {
        debugPrint('Failed to save to gallery: $e');
      }

      final screenSize = MediaQuery.of(context).size;
      final formData = FormData.fromMap({
        'content': 'Captured via Shop Radar Snap Mode 📸 #SnapMode #${widget.filterName}',
        'images': [
          await MultipartFile.fromFile(imgFile.path, filename: 'snap.jpg'),
        ],
        'interactiveElements': jsonEncode(_stickers.map((s) => {
          'type': s.type,
          'x': s.position.dx / screenSize.width,
          'y': s.position.dy / screenSize.height,
          'scale': s.scale,
          'rotation': s.rotation,
          'data': s.data,
        }).toList()),
        if (_music != null) 'music': jsonEncode(_music!.toJson()),
      });

      final success = await ref.read(socialProvider.notifier).createPost(formData);
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted to Feed!')));
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post')));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      debugPrint('Post error: $e');
    }
  }

  void _saveVideoToGallery() async {
    setState(() => _isSaving = true);
    try {
      await Gal.putVideo(widget.mediaPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Gallery!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _postToStoryDirectly() async {
    setState(() => _isSaving = true);
    try {
      final screenSize = MediaQuery.of(context).size;
      final formData = FormData.fromMap({
        'caption': 'Captured via Shop Radar Snap Mode 📸 #SnapMode #${widget.filterName}',
        'image': await MultipartFile.fromFile(
          widget.mediaPath, 
          filename: widget.isVideo ? 'snap.mp4' : 'snap.jpg'
        ),
        'interactiveElements': jsonEncode(_stickers.map((s) => {
          'type': s.type,
          'x': s.position.dx / screenSize.width,
          'y': s.position.dy / screenSize.height,
          'scale': s.scale,
          'rotation': s.rotation,
          'data': s.data,
        }).toList()),
        if (_music != null) 'music': jsonEncode(_music!.toJson()),
      });

      final success = await ref.read(socialProvider.notifier).createStory(formData);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Your Story!')));
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add to story')));
        }
      }
    } catch (e) {
      debugPrint('Story error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _postVideoDirectly() async {
    setState(() => _isSaving = true);
    try {
      final screenSize = MediaQuery.of(context).size;
      final formData = FormData.fromMap({
        'content': 'Captured via Shop Radar Snap Mode 📸 #SnapMode #${widget.filterName}',
        'video': [
          await MultipartFile.fromFile(widget.mediaPath, filename: 'snap.mp4'),
        ],
        'interactiveElements': jsonEncode(_stickers.map((s) => {
          'type': s.type,
          'x': s.position.dx / screenSize.width,
          'y': s.position.dy / screenSize.height,
          'scale': s.scale,
          'rotation': s.rotation,
          'data': s.data,
        }).toList()),
        if (_music != null) 'music': jsonEncode(_music!.toJson()),
      });

      final success = await ref.read(socialProvider.notifier).createPost(formData);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted to Feed!')));
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post')));
        }
      }
    } catch (e) {
      debugPrint('Post error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showStickerPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: StickerToolsPanel(
            onStickerSelected: (type) {
              Navigator.pop(context);
              _handleStickerSelection(type);
            },
          ),
        );
      },
    );
  }

  void _handleStickerSelection(String type) async {
    if (type == 'music') {
      final PostMusic? selectedMusic = await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const MusicPickerSheet(),
      );
      if (selectedMusic != null) {
        _music = selectedMusic;
        _canvasKey.currentState?.addSticker(type, {
          'title': selectedMusic.title,
          'artist': selectedMusic.artist,
          'url': selectedMusic.url,
        });
      }
      return;
    }

    if (['mention', 'location', 'hashtag', 'text', 'poll'].contains(type)) {
      String hint = 'Enter text';
      String prefix = '';
      if (type == 'mention') prefix = '@';
      if (type == 'hashtag') prefix = '#';
      if (type == 'location') hint = 'Enter location name';
      if (type == 'poll') hint = 'Ask a question...';

      final TextEditingController _textCtrl = TextEditingController(text: prefix);
      
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Add $type', style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: _textCtrl,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _textCtrl.text),
              child: const Text('Add', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty && result != prefix) {
        _canvasKey.currentState?.addSticker(type, {'text': result});
      }
      return;
    }

    _canvasKey.currentState?.addSticker(type, {'text': 'Custom $type'});
  }

  void _showTextEditor(StickerData sticker) {
    if (sticker.type != 'text') return;
    
    final TextEditingController _controller = TextEditingController(text: sticker.data['text'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 20),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter text...'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _canvasKey.currentState?.updateStickerData(sticker.id, {'text': _controller.text});
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickerContent(BuildContext context, StickerData sticker) {
    IconData icon;
    Color color;
    switch (sticker.type) {
      case 'poll':
        icon = Icons.poll;
        color = Colors.cyan;
        break;
      case 'question':
        icon = Icons.help_outline;
        color = Colors.purple;
        break;
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
                  Text(sticker.data['title'] ?? 'Song', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text(sticker.data['artist'] ?? 'Artist', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      case 'mention':
        icon = Icons.alternate_email;
        color = Colors.orange;
        break;
      case 'location':
        icon = Icons.location_on;
        color = Colors.purpleAccent;
        break;
      case 'text':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
          child: Text(
            sticker.data['text']?.isEmpty ?? true ? 'Double tap to edit' : sticker.data['text'],
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      default:
        icon = Icons.star;
        color = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            sticker.type.toUpperCase(),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget editorArea;
    if (!widget.isVideo) {
      // ─── FULL FEATURED IMAGE EDITOR ───
      editorArea = ProImageEditor.file(
        File(widget.mediaPath),
        key: editorKey,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {
            await _postEditedImage(bytes);
          },
          onCloseEditor: (mode, [p1]) => Navigator.pop(context),
        ),
        configs: const ProImageEditorConfigs(
          designMode: ImageEditorDesignMode.material,
          i18n: I18n(
            doneLoadingMsg: 'Preparing Post...',
          ),
        ),
      );
    } else {
      // ─── BASIC VIDEO PREVIEW ───
      editorArea = Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(widget.filter),
              child: (_videoController != null && _videoController!.value.isInitialized)
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _postToStoryDirectly,
                    icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline),
                    label: const Text('Your Story'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _postVideoDirectly,
                    icon: const Icon(Icons.send),
                    label: const Text('Feed Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveStickerCanvas(
            key: _canvasKey,
            onStickersUpdated: (stickers) {
              _stickers = stickers;
            },
            stickerBuilder: _buildStickerContent,
            onStickerDoubleTapped: _showTextEditor,
            child: editorArea,
          ),
          
          // Custom Top Bar overlay to hold Sticker Panel button and Undo/Redo
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(Icons.arrow_back, () => Navigator.pop(context)),
                Row(
                  children: [
                    _buildCircularButton(Icons.undo, () => _canvasKey.currentState?.undo()),
                    const SizedBox(width: 12),
                    _buildCircularButton(Icons.redo, () => _canvasKey.currentState?.redo()),
                    const SizedBox(width: 12),
                    _buildCircularButton(Icons.add_reaction_outlined, _showStickerPanel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class OverlayText {
  final String text;
  Offset offset;
  OverlayText({required this.text, required this.offset});
}
