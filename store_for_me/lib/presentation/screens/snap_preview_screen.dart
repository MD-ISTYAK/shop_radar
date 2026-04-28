import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';
import 'package:dio/dio.dart';

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

      final formData = FormData.fromMap({
        'content': 'Captured via Shop Radar Snap Mode 📸 #SnapMode #${widget.filterName}',
        'images': [
          await MultipartFile.fromFile(imgFile.path, filename: 'snap.jpg'),
        ],
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

  void _postVideoDirectly() async {
    setState(() => _isSaving = true);
    try {
      final formData = FormData.fromMap({
        'content': 'Captured via Shop Radar Snap Mode 📸 #SnapMode #${widget.filterName}',
        'video': [
          await MultipartFile.fromFile(widget.mediaPath, filename: 'snap.mp4'),
        ],
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isVideo) {
      // ─── FULL FEATURED IMAGE EDITOR ───
      return Scaffold(
        backgroundColor: Colors.black,
        body: ProImageEditor.file(
          File(widget.mediaPath),
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
        ),
      );
    }

    // ─── BASIC VIDEO PREVIEW ───
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
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
              ],
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(Icons.arrow_back, () => Navigator.pop(context)),
              ],
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
                    onPressed: _isSaving ? null : _saveVideoToGallery,
                    icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download),
                    label: const Text('Save Video'),
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
                    label: const Text('Post Video'),
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
