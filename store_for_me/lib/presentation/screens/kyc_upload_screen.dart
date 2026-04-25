import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../providers/delivery_partner_provider.dart';

class KYCUploadScreen extends ConsumerStatefulWidget {
  const KYCUploadScreen({super.key});

  @override
  ConsumerState<KYCUploadScreen> createState() => _KYCUploadScreenState();
}

class _KYCUploadScreenState extends ConsumerState<KYCUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, File?> _docs = {
    'aadhaar': null,
    'pan': null,
    'license': null,
    'vehicleRC': null,
    'selfie': null,
  };

  bool _isUploading = false;

  Future<void> _pickImage(String key) async {
    final XFile? image = await _picker.pickImage(
      source: key == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _docs[key] = File(image.path));
    }
  }

  Future<void> _submit() async {
    // Check if all are uploaded
    if (_docs.values.any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    setState(() => _isUploading = true);
    
    // Simulate upload and then self-verify for testing
    await Future.delayed(const Duration(seconds: 2));
    
    final success = await ref.read(deliveryPartnerProvider.notifier).verifySelf();
    
    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC Submitted and Verified Successfully!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit KYC')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('KYC Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Documents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Please provide clear photos of your documents for verification.',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildDocTile('Aadhaar Card', 'aadhaar', Icons.badge_outlined),
            _buildDocTile('PAN Card', 'pan', Icons.credit_card_outlined),
            _buildDocTile('Driving License', 'license', Icons.drive_eta_outlined),
            _buildDocTile('Vehicle RC', 'vehicleRC', Icons.description_outlined),
            _buildDocTile('Selfie with Vehicle', 'selfie', Icons.camera_alt_outlined),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: _isUploading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit KYC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            // Self verify button for testing (if they don't want to pick images)
            Center(
              child: TextButton(
                onPressed: () async {
                  final success = await ref.read(deliveryPartnerProvider.notifier).verifySelf();
                  if (success && mounted) Navigator.pop(context);
                },
                child: const Text('Quick Verify (Testing Only)', style: TextStyle(color: AppColors.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTile(String title, String key, IconData icon) {
    final file = _docs[key];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  file != null ? 'Image selected' : 'No image selected',
                  style: TextStyle(
                    color: file != null ? AppColors.success : AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _pickImage(key),
            icon: Icon(
              file != null ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: file != null ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}








