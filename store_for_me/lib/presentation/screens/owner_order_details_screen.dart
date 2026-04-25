import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../providers/order_provider.dart';
import '../../data/models/order_model.dart';
import '../widgets/common_widgets.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class OwnerOrderDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const OwnerOrderDetailsScreen({super.key, required this.order});

  @override
  ConsumerState<OwnerOrderDetailsScreen> createState() => _OwnerOrderDetailsScreenState();
}

class _OwnerOrderDetailsScreenState extends ConsumerState<OwnerOrderDetailsScreen> {
  final _otpController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isProcessing = false;
  bool _isPackedSuccessfully = false;

  @override
  void initState() {
    super.initState();
    // If order is already packed or in a later fulfillment stage, set state
    final status = widget.order.status;
    if (['packed', 'ready', 'delivery_assigned', 'picked_up', 'out_for_delivery', 'delivered'].contains(status)) {
      _isPackedSuccessfully = true;
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) return;
    
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1000,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
        }
      });
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    final success = await ref.read(orderProvider.notifier).acceptOrder(widget.order.id);
    setState(() => _isProcessing = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted successfully!')));
      // We stay on page to allow packing
      ref.read(orderProvider.notifier).fetchShopOrders();
    }
  }

  Future<void> _handlePack() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one image is required to mark as packed')));
      return;
    }

    setState(() => _isProcessing = true);
    
    final formData = FormData.fromMap({
      'status': 'packed',
    });

    for (var file in _selectedImages) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ));
    }

    final success = await ref.read(orderProvider.notifier).packOrder(widget.order.id, formData);
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      setState(() => _isPackedSuccessfully = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as packed!')));
      ref.read(orderProvider.notifier).fetchShopOrders();
    }
  }

  Future<void> _handleCompletePickup() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 6-digit code')));
      return;
    }
    setState(() => _isProcessing = true);
    final error = await ref.read(orderProvider.notifier).completeShopPickup(widget.order.id, _otpController.text.trim());
    setState(() => _isProcessing = false);
    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order successfully delivered!')));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error!),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _handleDispatchToDriver() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 6-digit PICKUP code')));
      return;
    }
    setState(() => _isProcessing = true);
    final success = await ref.read(orderProvider.notifier).verifyPickupCode(widget.order.id, _otpController.text.trim());
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order successfully dispatched with driver!')));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid dispatch code'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // We watch the order state to get updates if status changes
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrders.firstWhere((o) => o.id == widget.order.id, orElse: () => widget.order);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Order Details (Owner)', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order ID: ${order.shortId}', 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                  ),
                ),
                Text(
                  DateFormat('hh:mm a  dd-MM-yyyy').format(order.createdAt.toLocal()), 
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_getStatusColor(order.status) ?? Colors.transparent).withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (_getStatusColor(order.status) ?? Colors.transparent).withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: _getStatusColor(order.status)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Status', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                        Text(order.statusLabel.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, color: _getStatusColor(order.status))),
                      ],
                    ),
                  ),
                  if (order.deliveryType == 'shop_pickup')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                      child: const Text('PICKUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer Details
            const Text('Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: ${order.userId.substring(order.userId.length - 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (order.deliveryType != 'shop_pickup')
                          Text('Address: ${order.deliveryAddress}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items List
            const Text('Items to Prepare', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
              child: Column(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                          child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 24),

            // Packing Section (Only if Accepted or Packed)
            if (order.status == 'accepted' || order.status == 'packed' || order.status == 'ready') ...[
              const Text('Proof of Packing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              SizedBox(height: 12),
              if (!_isPackedSuccessfully) ...[
                Text('Upload up to 5 images of the packed items. At least one image is mandatory.', 
                           style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._selectedImages.map((file) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(file.path), width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImages.remove(file)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (_selectedImages.length < 5)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.none),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: AppColors.primary),
                                SizedBox(height: 4),
                                Text('Add Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isPackedSuccessfully ? 'Marked as Packed' : 'Mark as Packed',
                  isLoading: _isProcessing && !_isPackedSuccessfully,
                  onPressed: _isPackedSuccessfully ? null : _handlePack,
                  icon: _isPackedSuccessfully ? Icons.check_circle : null,
                  backgroundColor: _isPackedSuccessfully ? AppColors.success : null,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Verification Section (For Shop Pickup or Driver Handover)
            if (_isPackedSuccessfully && !order.isCompleted && ['packed', 'delivery_assigned'].contains(order.status)) ...[
              const Divider(height: 48),
              const Text('Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                order.deliveryType == 'shop_pickup' 
                  ? 'Ask the customer for the 6-digit code to verify the handover.'
                  : 'Ask the delivery driver for their 6-digit PICKUP code to dispatch the order.', 
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _otpController,
                label: order.deliveryType == 'shop_pickup' ? 'Customer Code' : 'Driver Code',
                hint: 'Enter 6-digit code',
                keyboardType: TextInputType.number,
                maxLength: 6,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: order.deliveryType == 'shop_pickup' ? 'Verify OTP & Complete' : 'Verify & Dispatch',
                  isLoading: _isProcessing && _isPackedSuccessfully,
                  onPressed: order.deliveryType == 'shop_pickup' ? _handleCompletePickup : _handleDispatchToDriver,
                ),
              ),
            ],

            // Action Buttons for initial state
            if (order.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Accept Order',
                  isLoading: _isProcessing,
                  onPressed: _handleAccept,
                ),
              ),

            if (order.isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                child: const Text('Order delivered successfully.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'accepted': return AppColors.info;
      case 'packed': case 'ready': return AppColors.success;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textLight;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}









