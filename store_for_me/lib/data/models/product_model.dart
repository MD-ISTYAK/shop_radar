class ProductModel {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final double discount;
  final List<String> images;
  final int stock;
  final bool isActive;
  final String itemType; // 'product' or 'service'
  final String serviceDuration; // e.g. '1 Hour', '30 Mins'
  final String bookingType; // 'instant' or 'appointment'

  ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.description = '',
    required this.price,
    this.discount = 0,
    this.images = const [],
    this.stock = 0,
    this.isActive = true,
    this.itemType = 'product',
    this.serviceDuration = '1 Hour',
    this.bookingType = 'instant',
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      shopId: json['shopId'] is Map ? json['shopId']['_id'] ?? '' : json['shopId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
      itemType: json['itemType'] ?? json['type'] ?? 'product',
      serviceDuration: json['serviceDuration'] ?? json['duration'] ?? '1 Hour',
      bookingType: json['bookingType'] ?? 'instant',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'discount': discount,
        'stock': stock,
        'itemType': itemType,
        'serviceDuration': serviceDuration,
        'bookingType': bookingType,
      };

  double get discountedPrice =>
      discount > 0 ? price - (price * discount / 100) : price;

  bool get inStock => isService || stock > 0;

  bool get hasDiscount => discount > 0;

  bool get isService => itemType.toLowerCase() == 'service';

  bool get isProduct => itemType.toLowerCase() != 'service';
}
