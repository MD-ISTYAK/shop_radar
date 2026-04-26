import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';
import 'package:dio/dio.dart';

class SnapPreviewScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final List<double> filter;
  final String filterName;

  const SnapPreviewScreen({
    super.key,
    required this.imagePath,
    required this.filter,
    required this.filterName,
  });

  @override
  ConsumerState<SnapPreviewScreen> createState() => _SnapPreviewScreenState();
}

class _SnapPreviewScreenState extends ConsumerState<SnapPreviewScreen> {
  final List<OverlayText> _overlays = [];
  bool _isSaving = false;

  void _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      await Gal.putImage(widget.imagePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Gallery!')),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addText() {
    String text = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => text = v,
          decoration: const InputDecoration(hintText: 'Enter text...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (text.isNotEmpty) {
                setState(() => _overlays.add(OverlayText(text: text, offset: const Offset(100, 100))));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _postDirectly() async {
    setState(() => _isSaving = true);
    try {
      final formData = FormData.fromMap({
        'content': 'Captured via Shop Radar Snap Mode 📸 #SnapMode #${widget.filterName}',
        'images': [
          await MultipartFile.fromFile(widget.imagePath, filename: 'snap.jpg'),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Image with Filter ───
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(widget.filter),
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
          ),

          // ─── Overlays ───
          for (var overlay in _overlays)
            Positioned(
              left: overlay.offset.dx,
              top: overlay.offset.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    overlay.offset += details.delta;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    overlay.text,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // ─── Top Bar ───
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
                    _buildCircularButton(Icons.text_fields, _addText),
                    const SizedBox(width: 15),
                    _buildCircularButton(Icons.emoji_emotions_outlined, () {}),
                  ],
                ),
              ],
            ),
          ),

          // ─── Bottom Actions ───
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveToGallery,
                    icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download),
                    label: const Text('Save'),
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
                    onPressed: _isSaving ? null : _postDirectly,
                    icon: const Icon(Icons.send),
                    label: const Text('Post'),
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
