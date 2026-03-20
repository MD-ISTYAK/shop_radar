import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../services/api_service.dart';

class ProductState {
  final List<ProductModel> products;
  final List<ProductModel> ownerProducts;
  final ProductModel? selectedProduct;
  final bool isLoading;
  final String? error;

  const ProductState({
    this.products = const [],
    this.ownerProducts = const [],
    this.selectedProduct,
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? ownerProducts,
    ProductModel? selectedProduct,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      products: products ?? this.products,
      ownerProducts: ownerProducts ?? this.ownerProducts,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final ApiService _api = ApiService();

  ProductNotifier() : super(const ProductState());

  Future<void> fetchProductsByShop(String shopId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getProductsByShop(shopId);
      if (response.data['success'] == true) {
        final products = (response.data['data'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
        state = state.copyWith(products: products, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load products');
    }
  }

  Future<void> fetchProductById(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getProductById(id);
      if (response.data['success'] == true) {
        final product = ProductModel.fromJson(response.data['data']);
        state = state.copyWith(selectedProduct: product, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load product');
    }
  }

  Future<void> fetchOwnerProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getOwnerProducts();
      if (response.data['success'] == true) {
        final products = (response.data['data'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
        state = state.copyWith(ownerProducts: products, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load products');
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _api.deleteProduct(id);
      if (response.data['success'] == true) {
        state = state.copyWith(
          ownerProducts: state.ownerProducts.where((p) => p.id != id).toList(),
        );
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier();
});
