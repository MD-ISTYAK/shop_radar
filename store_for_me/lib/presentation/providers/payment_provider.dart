import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

enum PaymentStatus { idle, loading, success, failed }

class PaymentState {
  final PaymentStatus status;
  final String? error;
  final String? lastPaymentId;
  final Map<String, dynamic>? razorpayOrderData;

  const PaymentState({
    this.status = PaymentStatus.idle,
    this.error,
    this.lastPaymentId,
    this.razorpayOrderData,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    String? error,
    String? lastPaymentId,
    Map<String, dynamic>? razorpayOrderData,
  }) {
    return PaymentState(
      status: status ?? this.status,
      error: error,
      lastPaymentId: lastPaymentId ?? this.lastPaymentId,
      razorpayOrderData: razorpayOrderData ?? this.razorpayOrderData,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final ApiService _api = ApiService();
  late final Razorpay _razorpay;

  // Callbacks for UI layer
  VoidCallback? onPaymentSuccess;
  VoidCallback? onPaymentFailure;

  PaymentNotifier() : super(const PaymentState()) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  String? _currentOrderId;

  /// Initiates the full payment flow:
  /// 1. Calls backend to create Razorpay order
  /// 2. Opens Razorpay checkout
  Future<void> initiatePayment({
    required String orderId,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    state = state.copyWith(status: PaymentStatus.loading, error: null);
    _currentOrderId = orderId;

    try {
      // 1. Create Razorpay order on backend
      final res = await _api.createPaymentOrder(orderId);
      if (res.data['success'] != true) {
        state = state.copyWith(
          status: PaymentStatus.failed,
          error: res.data['message'] ?? 'Failed to create payment order',
        );
        return;
      }

      final data = res.data['data'];
      state = state.copyWith(razorpayOrderData: data);

      // 2. Open Razorpay checkout
      final options = {
        'key': data['keyId'] ?? AppConstants.razorpayKey,
        'amount': data['amount'],
        'currency': data['currency'] ?? 'INR',
        'order_id': data['razorpayOrderId'],
        'name': 'Shop Radar',
        'description': 'Order Payment',
        'prefill': {
          'name': userName,
          'email': userEmail,
          'contact': userPhone,
        },
        'theme': {
          'color': '#4F46E5',
        },
        'modal': {
          'confirm_close': true,
        },
      };

      _razorpay.open(options);
    } catch (e) {
      state = state.copyWith(
        status: PaymentStatus.failed,
        error: 'Payment initialization failed. Please try again.',
      );
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) async {
    try {
      state = state.copyWith(status: PaymentStatus.loading);

      // Verify payment on backend
      final verifyRes = await _api.verifyPayment({
        'razorpayOrderId': response.orderId,
        'razorpayPaymentId': response.paymentId,
        'razorpaySignature': response.signature,
        'orderId': _currentOrderId,
      });

      if (verifyRes.data['success'] == true) {
        state = state.copyWith(
          status: PaymentStatus.success,
          lastPaymentId: response.paymentId,
        );
        onPaymentSuccess?.call();
      } else {
        state = state.copyWith(
          status: PaymentStatus.failed,
          error: 'Payment verification failed on server',
        );
        onPaymentFailure?.call();
      }
    } catch (e) {
      state = state.copyWith(
        status: PaymentStatus.failed,
        error: 'Payment succeeded but verification failed. Contact support.',
      );
      onPaymentFailure?.call();
    }
  }

  void _handleError(PaymentFailureResponse response) {
    state = state.copyWith(
      status: PaymentStatus.failed,
      error: response.message ?? 'Payment failed',
    );
    onPaymentFailure?.call();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  void reset() {
    state = const PaymentState();
    _currentOrderId = null;
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) => PaymentNotifier());
