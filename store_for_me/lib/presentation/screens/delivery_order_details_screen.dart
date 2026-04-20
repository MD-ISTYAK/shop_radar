import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../providers/delivery_partner_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class DeliveryOrderDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> delivery;
  const DeliveryOrderDetailsScreen({super.key, required this.delivery});

  @override
  ConsumerState<DeliveryOrderDetailsScreen> createState() => _DeliveryOrderDetailsScreenState();
}

class _DeliveryOrderDetailsScreenState extends ConsumerState<DeliveryOrderDetailsScreen> {
  final _otpController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isProcessing = false;

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) return;
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) _selectedImages = _selectedImages.sublist(0, 5);
      });
    }
  }

  Future<void> _handleComplete() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one photo is mandatory')));
      return;
    }
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid 6-digit OTP from customer')));
      return;
    }

    setState(() => _isProcessing = true);
    
    // Preparation for upload
    final formData = FormData.fromMap({
      'otp': _otpController.text,
    });
    for (var file in _selectedImages) {
      formData.files.add(MapEntry('images', await MultipartFile.fromFile(file.path)));
    }

    final success = await ref.read(deliveryPartnerProvider.notifier).completeDelivery(widget.delivery['_id'], formData);
    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery Completed Successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.delivery['status'] ?? '';
    final fullOrderId = widget.delivery['orderId'] is Map 
        ? widget.delivery['orderId']['_id'] 
        : widget.delivery['orderId'].toString();
    final shortId = fullOrderId.length > 8 
        ? fullOrderId.substring(fullOrderId.length - 8).toUpperCase() 
        : fullOrderId.toUpperCase();
    
    final shopName = widget.delivery['shopId']?['shopName'] ?? 'Shop';
    final address = widget.delivery['deliveryAddress'] ?? 'Address info';
    final pickupCode = widget.delivery['pickupCode'] ?? '000000';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Shop / Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), shape: BoxShape.circle),
                    child: const Icon(Icons.storefront, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shopName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        Text(status == 'packed' ? 'Ready for Pickup' : 'Out for Delivery', 
                             style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // PICKUP SECTION
            if (status == 'packed' || status == 'accepted' || status == 'partner_assigned' || status == 'delivery_assigned') ...[
              const Text('Pickup Identification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.divider)),
                child: Column(
                  children: [
                    QrImageView(
                      data: widget.delivery['orderId'] is Map ? widget.delivery['orderId']['_id'] : widget.delivery['orderId'].toString(),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 16),
                    const Text('Order QR Code', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    const Divider(height: 32),
                    Text(pickupCode, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 8, color: AppColors.primary)),
                    const Text('HANDOVER CODE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    const Text('Show this QR or tell the code to the shop owner to receive the package.', 
                               textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],

            // DELIVERY SECTION
            if (status == 'out_for_delivery' || status == 'picked_up') ...[
              const Text('Delivery Completion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CUSTOMER ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    Text(address, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Divider(height: 32),
                    
                    const Text('UPLOAD DELIVERY PROOF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._selectedImages.map((img) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(img.path), width: 80, height: 80, fit: BoxFit.cover),
                            ),
                          )),
                          if (_selectedImages.length < 5)
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.divider)),
                                child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _otpController,
                      label: 'Customer OTP',
                      hint: 'Enter 6-digit code',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Complete Delivery',
                        isLoading: _isProcessing,
                        onPressed: _handleComplete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
