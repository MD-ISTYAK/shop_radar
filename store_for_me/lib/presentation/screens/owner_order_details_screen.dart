import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
  bool _isProcessing = false;

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    final success = await ref.read(orderProvider.notifier).acceptOrder(widget.order.id);
    setState(() => _isProcessing = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted successfully!')));
      Navigator.pop(context);
    }
  }

  Future<void> _handlePack() async {
    setState(() => _isProcessing = true);
    // Passing an empty/mock form data since we don't have an image picker UI yet
    final formData = FormData.fromMap({'mock': 'true'});
    final success = await ref.read(orderProvider.notifier).packOrder(widget.order.id, formData);
    setState(() => _isProcessing = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as packed!')));
      Navigator.pop(context);
    }
  }

  Future<void> _handleCompletePickup() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 6-digit code')));
      return;
    }
    setState(() => _isProcessing = true);
    final success = await ref.read(orderProvider.notifier).completeShopPickup(widget.order.id, _otpController.text.trim());
    setState(() => _isProcessing = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order successfully delivered (Pickup)!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Pickup code or verification failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details (Owner)', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getStatusColor(order.status).withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: _getStatusColor(order.status)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Text('DELIVERY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer Details (Optional Placeholder)
            const Text('Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
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
                          Text('Address: ${order.deliveryAddress}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Items
            const Text('Items to Prepare', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
              child: Column(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                          child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.name.isNotEmpty ? item.name : 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.w500))),
                        Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(10), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Value', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Action Buttons based on status
            if (order.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Accept Order',
                  isLoading: _isProcessing,
                  onPressed: _handleAccept,
                ),
              )
            else if (order.status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Mark as Packed',
                  isLoading: _isProcessing,
                  onPressed: _handlePack,
                ),
              )
            else if ((order.status == 'packed' || order.status == 'ready') && order.deliveryType == 'shop_pickup') ...[
              const Text('Complete Pickup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Ask the customer for their 6-digit pickup code to release the order.', style: TextStyle(color: AppColors.textLight)),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _otpController,
                label: 'Customer OTP',
                hint: 'Enter 6-digit OTP',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.password_rounded,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Verify & Handover Order',
                  isLoading: _isProcessing,
                  onPressed: _handleCompletePickup,
                ),
              )
            ]
            else if (order.status == 'packed' && order.deliveryType != 'shop_pickup')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.info.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                child: const Text('Waiting for Delivery Partner to pick up this order.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.info)),
              )
            else if (order.isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                child: const Text('Order completed.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
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
      case 'out_for_delivery': return AppColors.primary;
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
