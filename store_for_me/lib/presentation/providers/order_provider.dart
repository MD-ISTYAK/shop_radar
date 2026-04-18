import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

class OrderState {
  final List<dynamic> activeOrders;
  final List<dynamic> orderHistory;
  final Map<String, dynamic>? shopStats;
  final bool isLoading;
  final String? error;

  OrderState({this.activeOrders = const [], this.orderHistory = const [], this.shopStats, this.isLoading = false, this.error});

  OrderState copyWith({List<dynamic>? activeOrders, List<dynamic>? orderHistory, Map<String, dynamic>? shopStats, bool? isLoading, String? error}) {
    return OrderState(
      activeOrders: activeOrders ?? this.activeOrders,
      orderHistory: orderHistory ?? this.orderHistory,
      shopStats: shopStats ?? this.shopStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final ApiService _api = ApiService();
  OrderNotifier() : super(OrderState());

  Future<void> fetchMyOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final activeRes = await _api.getMyOrders(status: 'pending');
      final historyRes = await _api.getMyOrders();
      state = state.copyWith(
        activeOrders: activeRes.data['data'] ?? [],
        orderHistory: historyRes.data['data'] ?? [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchShopOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getShopOrders();
      state = state.copyWith(activeOrders: res.data['data'] ?? [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchShopStats() async {
    try {
      final res = await _api.getShopOrderStats();
      state = state.copyWith(shopStats: res.data['data']);
    } catch (_) {}
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _api.updateOrderStatus(orderId, status);
      await fetchShopOrders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, {String reason = ''}) async {
    try {
      await _api.cancelOrder(orderId, reason: reason);
      await fetchMyOrders();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) => OrderNotifier());
