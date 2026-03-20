class DeliveryRequestModel {
  final String id;
  final String userId;
  final String shopId;
  final String shopName;
  final String shopLogo;
  final List<DeliveryItemModel> items;
  final String deliveryAddress;
  final String note;
  final String status;
  final double totalAmount;
  final DateTime createdAt;

  DeliveryRequestModel({
    required this.id,
    required this.userId,
    required this.shopId,
    this.shopName = '',
    this.shopLogo = '',
    this.items = const [],
    required this.deliveryAddress,
    this.note = '',
    this.status = 'pending',
    this.totalAmount = 0,
    required this.createdAt,
  });

  factory DeliveryRequestModel.fromJson(Map<String, dynamic> json) {
    return DeliveryRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? '',
      shopId: json['shopId'] is Map ? json['shopId']['_id'] ?? '' : json['shopId'] ?? '',
      shopName: json['shopId'] is Map ? json['shopId']['shopName'] ?? '' : '',
      shopLogo: json['shopId'] is Map ? json['shopId']['logo'] ?? '' : '',
      items: (json['items'] as List?)?.map((e) => DeliveryItemModel.fromJson(e)).toList() ?? [],
      deliveryAddress: json['deliveryAddress'] ?? '',
      note: json['note'] ?? '',
      status: json['status'] ?? 'pending',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      case 'delivered': return 'Delivered';
      default: return status;
    }
  }
}

class DeliveryItemModel {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  DeliveryItemModel({
    this.productId = '',
    required this.name,
    required this.quantity,
    this.price = 0,
  });

  factory DeliveryItemModel.fromJson(Map<String, dynamic> json) {
    return DeliveryItemModel(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'price': price,
  };
}
