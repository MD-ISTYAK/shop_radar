import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _captionController = TextEditingController();
  XFile? _selectedMedia;
  bool _isSubmitting = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final media = await picker.pickMedia(imageQuality: 85);
    if (media != null) {
      setState(() => _selectedMedia = media);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() => _selectedMedia = image);
    }
  }

  Future<void> _takeVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() => _selectedMedia = video);
    }
  }

  Future<void> _submitStory() async {
    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image/video'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final formData = FormData();
    formData.fields.add(MapEntry('caption', _captionController.text.trim()));
    formData.files.add(MapEntry(
      'image',
      await MultipartFile.fromFile(_selectedMedia!.path, filename: _selectedMedia!.name),
    ));

    final success = await ref.read(socialProvider.notifier).createStory(formData);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story uploaded! It will be visible for 24 hours.'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload story'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Story'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitStory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(0, 36),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Share'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Media preview
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                width: double.infinity,
                height: 350,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
                  image: _selectedMedia != null && !_selectedMedia!.path.endsWith('.mp4') // basic check for image
                      ? DecorationImage(
                          image: FileImage(File(_selectedMedia!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedMedia == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 64, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          Text('Tap to select photo/video', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        ],
                      )
                    : (_selectedMedia!.path.endsWith('.mp4') || _selectedMedia!.name.toLowerCase().endsWith('.mp4')
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_file, size: 64, color: AppColors.primary),
                              SizedBox(height: 12),
                              Text('Video Selected', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : null),
              ),
            ),
            const SizedBox(height: 16),

            // Camera/Gallery buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickMedia,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Photo'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _takeVideo,
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: const Text('Video'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Caption
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
              ),
              child: TextField(
                controller: _captionController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Add a caption (optional)...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: AppColors.textLight),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stories disappear after 24 hours',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
