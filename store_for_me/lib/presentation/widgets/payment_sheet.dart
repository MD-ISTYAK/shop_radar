import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';

/// Bottom sheet for payment confirmation & Razorpay checkout
class PaymentSheet extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;
  final String? shopName;
  final int? itemCount;

  const PaymentSheet({
    super.key,
    required this.orderId,
    required this.amount,
    this.shopName,
    this.itemCount,
  });

  /// Show the payment sheet as a modal bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    required double amount,
    String? shopName,
    int? itemCount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentSheet(
        orderId: orderId,
        amount: amount,
        shopName: shopName,
        itemCount: itemCount,
      ),
    );
  }

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  @override
  void initState() {
    super.initState();
    // Set up callbacks
    final notifier = ref.read(paymentProvider.notifier);
    notifier.onPaymentSuccess = () {
      if (mounted) Navigator.pop(context, true);
    };
    notifier.onPaymentFailure = () {
      // Stay open to show error
    };
  }

  @override
  void dispose() {
    ref.read(paymentProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payment_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  if (widget.shopName != null)
                    Text(
                      widget.shopName!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider.withAlpha(isDark ? 50 : 128)),
            ),
            child: Column(
              children: [
                _summaryRow('Order ID', '#${widget.orderId.substring(widget.orderId.length - 8)}'),
                if (widget.itemCount != null) ...[
                  const SizedBox(height: 8),
                  _summaryRow('Items', '${widget.itemCount}'),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                _summaryRow(
                  'Total',
                  '₹${widget.amount.toStringAsFixed(2)}',
                  isBold: true,
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Secure payment powered by Razorpay',
                  style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Error message
          if (paymentState.status == PaymentStatus.failed && paymentState.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paymentState.error!,
                      style: const TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Success message
          if (paymentState.status == PaymentStatus.success) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: AppColors.success),
                  SizedBox(height: 8),
                  Text(
                    'Payment Successful!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: paymentState.status == PaymentStatus.success
                ? ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  )
                : ElevatedButton(
                    onPressed: paymentState.status == PaymentStatus.loading
                        ? null
                        : () {
                            ref.read(paymentProvider.notifier).initiatePayment(
                              orderId: widget.orderId,
                              userName: authState.user?.name ?? '',
                              userEmail: authState.user?.email ?? '',
                              userPhone: authState.user?.phone ?? '',
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: paymentState.status == PaymentStatus.loading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                'Pay ₹${widget.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
