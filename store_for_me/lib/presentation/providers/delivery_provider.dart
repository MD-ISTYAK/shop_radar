import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_model.dart';
import '../../services/api_service.dart';

class DeliveryState {
  final List<DeliveryRequestModel> myRequests;
  final List<DeliveryRequestModel> shopRequests;
  final bool isLoading;
  final String? message;

  const DeliveryState({
    this.myRequests = const [],
    this.shopRequests = const [],
    this.isLoading = false,
    this.message,
  });

  DeliveryState copyWith({
    List<DeliveryRequestModel>? myRequests,
    List<DeliveryRequestModel>? shopRequests,
    bool? isLoading,
    String? message,
  }) {
    return DeliveryState(
      myRequests: myRequests ?? this.myRequests,
      shopRequests: shopRequests ?? this.shopRequests,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }
}

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final ApiService _api = ApiService();

  DeliveryNotifier() : super(const DeliveryState());

  Future<void> fetchMyRequests() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getMyDeliveryRequests();
      if (response.data['success'] == true) {
        final requests = (response.data['data'] as List)
            .map((e) => DeliveryRequestModel.fromJson(e))
            .toList();
        state = state.copyWith(myRequests: requests, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchShopRequests() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getShopDeliveryRequests();
      if (response.data['success'] == true) {
        final requests = (response.data['data'] as List)
            .map((e) => DeliveryRequestModel.fromJson(e))
            .toList();
        state = state.copyWith(shopRequests: requests, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createRequest(Map<String, dynamic> data) async {
    try {
      final response = await _api.createDeliveryRequest(data);
      if (response.data['success'] == true) {
        await fetchMyRequests();
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      final response = await _api.updateDeliveryStatus(id, status);
      if (response.data['success'] == true) {
        await fetchShopRequests();
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  return DeliveryNotifier();
});
