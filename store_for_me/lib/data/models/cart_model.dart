import 'product_model.dart';

class CartModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final int totalItems;
  final double totalPrice;

  CartModel({
    required this.id,
    required this.userId,
    required this.items,
    this.totalItems = 0,
    this.totalPrice = 0,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((e) => CartItemModel.fromJson(e))
            .toList() ??
        [];

    return CartModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: items,
      totalItems: json['totalItems'] ?? items.fold(0, (sum, item) => sum + item.quantity),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }
}

class CartItemModel {
  final String id;
  final ProductModel? product;
  final String productId;
  final int quantity;

  CartItemModel({
    this.id = '',
    this.product,
    required this.productId,
    required this.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['_id'] ?? '',
      product: json['productId'] is Map
          ? ProductModel.fromJson(json['productId'])
          : null,
      productId: json['productId'] is Map
          ? json['productId']['_id'] ?? ''
          : json['productId'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  double get itemTotal {
    if (product == null) return 0;
    return product!.discountedPrice * quantity;
  }
}
