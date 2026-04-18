import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../data/models/order_model.dart';

class OrderState {
  final List<OrderModel> activeOrders;
  final List<OrderModel> orderHistory;
  final Map<String, dynamic>? shopStats;
  final bool isLoading;
  final String? error;

  OrderState({this.activeOrders = const [], this.orderHistory = const [], this.shopStats, this.isLoading = false, this.error});

  OrderState copyWith({List<OrderModel>? activeOrders, List<OrderModel>? orderHistory, Map<String, dynamic>? shopStats, bool? isLoading, String? error}) {
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

      final activeList = (activeRes.data['data'] as List).map((o) => OrderModel.fromJson(o)).toList();
      final historyList = (historyRes.data['data'] as List).map((o) => OrderModel.fromJson(o)).toList();

      state = state.copyWith(
        activeOrders: activeList,
        orderHistory: historyList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchShopOrders({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getShopOrders(search: search);
      final list = (res.data['data'] as List).map((o) => OrderModel.fromJson(o)).toList();
      state = state.copyWith(activeOrders: list, isLoading: false);
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

  Future<bool> acceptOrder(String orderId) async {
    try {
      await _api.acceptOrder(orderId);
      await fetchShopOrders();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> packOrder(String orderId, FormData data) async {
    try {
      await _api.packOrder(orderId, data);
      await fetchShopOrders();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> verifyPickupCode(String orderId, String code) async {
    try {
      await _api.verifyPickupCode(orderId, code);
      await fetchShopOrders();
      return true;
    } catch (_) { return false; }
  }

  Future<String?> completeShopPickup(String id, String otp) async {
    debugPrint('--- Handover Verification DEBUG (Provider) ---');
    debugPrint('Order ID: $id');
    debugPrint('Verification Code: $otp');
    debugPrint('----------------------------------------');
    try {
      await _api.completeShopPickup(id, otp);
      await fetchShopOrders();
      return null; // Success
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return e.response?.data['message'] ?? e.toString();
      }
      return e.toString();
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
