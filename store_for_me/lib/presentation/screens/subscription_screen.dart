import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/custom_button.dart';
import 'dart:ui';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  late Razorpay _razorpay;
  String? _pendingPlanId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingPlanId == null) return;
    
    final verified = await ref.read(subscriptionProvider.notifier).verifyPayment({
      'razorpay_order_id': response.orderId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
      'planId': _pendingPlanId,
    });

    if (verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Welcome to your new plan!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: AppColors.error),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> _subscribe(dynamic plan) async {
    if (plan['price'] == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already on the Free plan.')),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) return;

    _pendingPlanId = plan['id'];
    
    final orderData = await ref.read(subscriptionProvider.notifier).createOrder(plan['id']);
    
    if (orderData != null) {
      var options = {
        'key': 'rzp_test_YourKeyIdHere', // Must match backend environment ideally, but test key here for flutter demo
        'amount': orderData['amount'],
        'name': 'Shop Radar',
        'order_id': orderData['orderId'],
        'description': '${plan['name']} Subscription',
        'prefill': {
          'contact': user.phone,
          'email': user.email,
        },
        'theme': {
          'color': '#6366F1'
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Upgrade Your Plan', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
          ),
        ),
        child: subState.isLoading && subState.plans.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Unlock Your Business Potential',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current Plan: ${user?.subscriptionPlan.toUpperCase() ?? 'FREE'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 30),
                    ...subState.plans.map((plan) => _buildPlanCard(plan, user?.subscriptionPlan == plan['id'])),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan, bool isCurrent) {
    final isUltra = plan['id'] == 'ultra_pro';
    final isPro = plan['id'] == 'pro';

    List<Color> gradientColors = [Colors.white.withAlpha(20), Colors.white.withAlpha(5)];
    Color borderColor = Colors.white.withAlpha(20);

    if (isUltra) {
      gradientColors = [AppColors.secondary.withAlpha(150), AppColors.secondary.withAlpha(40)];
      borderColor = AppColors.secondary;
    } else if (isPro) {
      gradientColors = [AppColors.primary.withAlpha(150), AppColors.primary.withAlpha(40)];
      borderColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUltra)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('BEST VALUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['name'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${plan['price']}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        if (plan['price'] > 0)
                          const Text('/ month', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...(plan['features'] as List).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(feature.toString(), style: const TextStyle(color: Colors.white, fontSize: 15))),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                CustomButton(
                  text: isCurrent ? 'Current Plan' : (plan['price'] == 0 ? 'Included' : 'Upgrade Now'),
                  onPressed: (isCurrent || plan['price'] == 0) ? null : () => _subscribe(plan),
                  backgroundColor: isCurrent ? Colors.grey : (isUltra ? AppColors.secondary : AppColors.primary),
                  isLoading: ref.watch(subscriptionProvider).isLoading && _pendingPlanId == plan['id'],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
