import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/business_model.dart';
import '../../services/api_service.dart';

class BusinessState {
  final List<BusinessModel> businesses;
  final bool isLoading;
  final String? error;

  BusinessState({
    this.businesses = const [],
    this.isLoading = false,
    this.error,
  });

  BusinessState copyWith({
    List<BusinessModel>? businesses,
    bool? isLoading,
    String? error,
  }) {
    return BusinessState(
      businesses: businesses ?? this.businesses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasBusinesses => businesses.isNotEmpty;
  int get businessCount => businesses.length;

  List<BusinessModel> get shopBusinesses =>
      businesses.where((b) => b.isShop).toList();
  List<BusinessModel> get deliveryBusinesses =>
      businesses.where((b) => b.isDeliveryPartner).toList();
}

class BusinessNotifier extends StateNotifier<BusinessState> {
  final ApiService _api = ApiService();

  BusinessNotifier() : super(BusinessState());

  Future<void> fetchBusinesses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getMyBusinesses();
      if (res.data['success'] == true) {
        final businesses = (res.data['data'] as List)
            .map((e) => BusinessModel.fromJson(e))
            .toList();
        state = state.copyWith(businesses: businesses, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registerBusiness({
    required String businessType,
    required String businessName,
    String? description,
    String? category,
    String? serviceArea,
    String? contactPhone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.registerBusiness({
        'businessType': businessType,
        'businessName': businessName,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (serviceArea != null) 'serviceArea': serviceArea,
        if (contactPhone != null) 'contactPhone': contactPhone,
      });
      if (res.data['success'] == true) {
        await fetchBusinesses();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: res.data['message'] ?? 'Registration failed',
      );
      return false;
    } catch (e) {
      String errorMsg = 'An error occurred';
      try {
        final dioError = e as dynamic;
        if (dioError.response?.data != null) {
          errorMsg = dioError.response.data['message'] ?? errorMsg;
        }
      } catch (_) {}
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> deleteBusiness(String businessId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.deleteBusiness(businessId);
      if (res.data['success'] == true) {
        await fetchBusinesses();
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final businessProvider =
    StateNotifierProvider<BusinessNotifier, BusinessState>(
        (ref) => BusinessNotifier());
