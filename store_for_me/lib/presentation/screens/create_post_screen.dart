import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';
import '../../services/video_compress_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isSubmitting = false;
  bool _isCompressing = false;
  double _compressProgress = 0.0;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(5 - _selectedImages.length));
        _selectedVideo = null; // Clear video if images selected
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
        _selectedImages.clear(); // Clear images if video selected
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some content or images'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final formData = FormData();
    formData.fields.add(MapEntry('content', _contentController.text.trim()));
    formData.fields.add(const MapEntry('type', 'post'));

    if (_selectedVideo != null) {
      // Compress the video before uploading
      setState(() {
        _isCompressing = true;
        _compressProgress = 0.0;
      });

      final compressor = VideoCompressService();
      final compressedFile = await compressor.compressVideo(_selectedVideo!.path);

      setState(() => _isCompressing = false);

      formData.files.add(MapEntry(
        'video',
        await MultipartFile.fromFile(compressedFile.path, filename: compressedFile.path.split(Platform.pathSeparator).last),
      ));
    } else {
      for (var image in _selectedImages) {
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ));
      }
    }

    final success = await ref.read(socialProvider.notifier).createPost(formData);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      // Clean up compression temp files
      VideoCompressService().cleanUp();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create post'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: (_isSubmitting || _isCompressing) ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(0, 36),
              ),
              child: (_isSubmitting || _isCompressing)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        if (_isCompressing) ...[
                          const SizedBox(width: 8),
                          const Text('Compressing...', style: TextStyle(fontSize: 12)),
                        ],
                      ],
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content input
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'What\'s happening at your shop?',
                  hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),

            // Selected images
            if (_selectedImages.isNotEmpty) ...[
              Text('Photos (${_selectedImages.length}/5)', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImages[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ],

            // Selected video
            if (_selectedVideo != null) ...[
              Text('Video Selected', style: const TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_file, size: 48, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text('1 Video Attached', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedVideo = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Add photos/video button
            Row(
              children: [
                if (_selectedImages.length < 5 && _selectedVideo == null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(_selectedImages.isEmpty ? 'Add Photos' : 'Add More Photos'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (_selectedImages.isEmpty && _selectedVideo == null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_camera_back_outlined),
                      label: const Text('Add Video/Reel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}







