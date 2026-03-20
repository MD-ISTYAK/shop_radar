import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/shop_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class ShopState {
  final List<ShopModel> shops;
  final ShopModel? selectedShop;
  final ShopModel? ownerShop;
  final Map<String, dynamic>? analytics;
  final bool isLoading;
  final String? error;
  final String selectedCategory;
  final String searchQuery;
  final Position? userLocation;

  const ShopState({
    this.shops = const [],
    this.selectedShop,
    this.ownerShop,
    this.analytics,
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.userLocation,
  });

  ShopState copyWith({
    List<ShopModel>? shops,
    ShopModel? selectedShop,
    ShopModel? ownerShop,
    Map<String, dynamic>? analytics,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
    Position? userLocation,
  }) {
    return ShopState(
      shops: shops ?? this.shops,
      selectedShop: selectedShop ?? this.selectedShop,
      ownerShop: ownerShop ?? this.ownerShop,
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  final ApiService _api = ApiService();
  final LocationService _locationService = LocationService();

  ShopNotifier() : super(const ShopState());

  Future<void> fetchNearbyShops() async {
    state = state.copyWith(isLoading: true);
    try {
      // Get user location
      Position? position = state.userLocation;
      if (position == null) {
        position = await _locationService.getCurrentLocation();
        if (position != null) {
          state = state.copyWith(userLocation: position);
        }
      }

      final response = await _api.getNearbyShops(
        lat: position?.latitude,
        lng: position?.longitude,
        category: state.selectedCategory,
        search: state.searchQuery,
      );

      if (response.data['success'] == true) {
        final shops = (response.data['data'] as List)
            .map((e) => ShopModel.fromJson(e))
            .toList();
        state = state.copyWith(shops: shops, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load shops');
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    fetchNearbyShops();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchNearbyShops();
  }

  Future<void> fetchShopById(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getShopById(id);
      if (response.data['success'] == true) {
        final shop = ShopModel.fromJson(response.data['data']);
        state = state.copyWith(selectedShop: shop, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load shop');
    }
  }

  Future<void> fetchOwnerShop() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getOwnerShop();
      if (response.data['success'] == true) {
        final shop = ShopModel.fromJson(response.data['data']['shop']);
        final analytics = response.data['data']['analytics'] as Map<String, dynamic>?;
        state = state.copyWith(
          ownerShop: shop,
          analytics: analytics,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'No shop found');
    }
  }

  Future<bool> toggleShopStatus() async {
    if (state.ownerShop == null) return false;
    try {
      final response = await _api.toggleShopStatus(state.ownerShop!.id);
      if (response.data['success'] == true) {
        final updatedShop = ShopModel.fromJson(response.data['data']);
        state = state.copyWith(ownerShop: updatedShop);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> updateShopStatus(String status) async {
    if (state.ownerShop == null) return false;
    try {
      final response = await _api.updateShopStatus(state.ownerShop!.id, status);
      if (response.data['success'] == true) {
        final updatedShop = ShopModel.fromJson(response.data['data']);
        state = state.copyWith(ownerShop: updatedShop);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> updateCrowdLevel(String crowdLevel) async {
    if (state.ownerShop == null) return false;
    try {
      final response = await _api.updateCrowdLevel(state.ownerShop!.id, crowdLevel);
      if (response.data['success'] == true) {
        final updatedShop = ShopModel.fromJson(response.data['data']);
        state = state.copyWith(ownerShop: updatedShop);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  return ShopNotifier();
});
