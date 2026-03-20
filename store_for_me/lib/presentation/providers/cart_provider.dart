import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_model.dart';
import '../../services/api_service.dart';

class CartState {
  final CartModel? cart;
  final bool isLoading;
  final String? error;
  final String? message;

  const CartState({this.cart, this.isLoading = false, this.error, this.message});

  CartState copyWith({CartModel? cart, bool? isLoading, String? error, String? message}) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      message: message,
    );
  }

  int get itemCount => cart?.totalItems ?? 0;
  double get totalPrice => cart?.totalPrice ?? 0;
}

class CartNotifier extends StateNotifier<CartState> {
  final ApiService _api = ApiService();

  CartNotifier() : super(const CartState());

  Future<void> fetchCart() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getCart();
      if (response.data['success'] == true) {
        final cart = CartModel.fromJson(response.data['data']);
        state = state.copyWith(cart: cart, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addToCart(String productId, {int quantity = 1}) async {
    try {
      final response = await _api.addToCart({
        'productId': productId,
        'quantity': quantity,
      });
      if (response.data['success'] == true) {
        await fetchCart();
        state = state.copyWith(message: 'Added to cart');
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add to cart');
    }
    return false;
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      final response = await _api.updateCartItem({
        'productId': productId,
        'quantity': quantity,
      });
      if (response.data['success'] == true) {
        await fetchCart();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update cart');
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      final response = await _api.removeFromCart(productId);
      if (response.data['success'] == true) {
        await fetchCart();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove item');
    }
  }

  Future<bool> checkout({String? deliveryAddress}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.checkout({
        'deliveryAddress': deliveryAddress ?? '',
      });
      if (response.data['success'] == true) {
        await fetchCart();
        state = state.copyWith(message: 'Order placed successfully!', isLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Checkout failed');
    }
    return false;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
