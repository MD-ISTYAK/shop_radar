import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        state = state.copyWith(error: e.response?.data['message']);
      }
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

  // ===================== FLEXIBLE ORDERS =====================
  Future<Map<String, dynamic>?> createFlexibleOrder({
    required String shopId,
    required String description,
    String deliveryType = 'home_delivery',
    String? deliveryAddress,
    double? lat,
    double? lng,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.createFlexibleOrder({
        'shopId': shopId,
        'description': description,
        'deliveryType': deliveryType,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });

      state = state.copyWith(isLoading: false);
      if (res.data['success'] == true) {
        await fetchMyOrders();
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return null;
    }
  }

  Future<bool> confirmOrderPrice(String orderId, double price) async {
    try {
      final res = await _api.confirmOrderPrice(orderId, price);
      if (res.data['success'] == true) {
        await fetchShopOrders();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return false;
    }
  }

  Future<bool> acceptOrderPrice(String orderId) async {
    try {
      final res = await _api.acceptOrderPrice(orderId);
      if (res.data['success'] == true) {
        await fetchMyOrders();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return false;
    }
  }

  // ===================== PAYMENTS =====================
  Future<Map<String, dynamic>?> createPaymentOrder(String orderId) async {
    try {
      final res = await _api.createPaymentOrder(orderId);
      if (res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    try {
      final res = await _api.verifyPayment({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'orderId': orderId,
      });
      if (res.data['success'] == true) {
        await fetchMyOrders();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      return e.response?.data['message'] ?? 'Something went wrong';
    }
    return 'Connection error. Please try again.';
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) => OrderNotifier());
