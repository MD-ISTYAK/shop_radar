import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import 'auth_provider.dart';

class SubscriptionState {
  final List<dynamic> plans;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.plans = const [],
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    List<dynamic>? plans,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiService _api = ApiService();
  final Ref ref;

  SubscriptionNotifier(this.ref) : super(const SubscriptionState()) {
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getSubscriptionPlans();
      if (response.data['success'] == true) {
        state = state.copyWith(
          plans: response.data['data'] as List<dynamic>,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load plans',
      );
    }
  }

  Future<Map<String, dynamic>?> createOrder(String planId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.createSubscriptionOrder(planId);
      state = state.copyWith(isLoading: false);
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to create order');
      return null;
    }
  }

  Future<bool> verifyPayment(Map<String, dynamic> paymentData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.verifySubscriptionPayment(paymentData);
      state = state.copyWith(isLoading: false);
      if (response.data['success'] == true) {
        // Refresh user profile to get new subscription status
        await ref.read(authProvider.notifier).checkAuth();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Payment verification failed');
      return false;
    }
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref);
});
