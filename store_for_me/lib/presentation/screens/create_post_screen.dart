import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import 'package:store_for_me/presentation/providers/social_provider.dart';
import 'package:store_for_me/presentation/widgets/premium_widgets.dart';

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
  double _uploadProgress = 0;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(5 - _selectedImages.length));
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
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

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });

    final formData = FormData.fromMap({
      'content': _contentController.text.trim(),
      'type': 'post',
      if (_selectedVideo != null)
        'video': await MultipartFile.fromFile(
          _selectedVideo!.path,
          filename: _selectedVideo!.name,
        ),
      'images': [
        for (var image in _selectedImages)
          await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
      ],
    });

    final success = await ref.read(socialProvider.notifier).createPost(
      formData,
      onSendProgress: (sent, total) {
        if (total > 0) {
          setState(() {
            _uploadProgress = sent / total;
          });
        }
      },
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, 
            color: Theme.of(context).iconTheme.color, 
            size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(
            fontSize: 18, 
            fontWeight: FontWeight.w700, 
            color: Theme.of(context).textTheme.titleLarge?.color
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: PremiumButton(
              text: 'Post',
              onPressed: _isSubmitting ? () {} : _submitPost,
              width: 80,
              height: 36,
              isLoading: _isSubmitting,
              isFullWidth: false,
            ),
          ),
        ],
        bottom: _isSubmitting
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                maxLength: 2000,
                style: GoogleFonts.inter(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Share what\'s happening...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textLight),
                  border: InputBorder.none,
                  counterStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 10),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // Media Selection Section
            if (_selectedImages.isNotEmpty) ...[
              _buildSectionTitle('Photos (${_selectedImages.length}/5)'),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return _buildMediaPreview(File(_selectedImages[index].path), () {
                      setState(() => _selectedImages.removeAt(index));
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_selectedVideo != null) ...[
              _buildSectionTitle('Video Selected'),
              const SizedBox(height: 12),
              _buildVideoPreview(),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                if (_selectedImages.length < 5)
                  Expanded(
                    child: _buildMediaAction('Add Photos', Icons.photo_library_rounded, _pickImages),
                  ),
                if (_selectedVideo == null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMediaAction('Add Video', Icons.video_camera_back_rounded, _pickVideo),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textLight),
    );
  }

  Widget _buildMediaPreview(File file, VoidCallback onRemove) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.video_file_rounded, size: 48, color: AppColors.textLight),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _selectedVideo = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: PremiumGlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
