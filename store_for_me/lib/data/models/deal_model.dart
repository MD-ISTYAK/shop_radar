class DealModel {
  final String id;
  final String shopId;
  final String shopName;
  final String shopLogo;
  final String shopAddress;
  final String ownerId;
  final String title;
  final String description;
  final String image;
  final double originalPrice;
  final double dealPrice;
  final int discountPercent;
  final DateTime expiresAt;
  final bool isActive;
  final int engagementCount;
  final List<String> savedBy;
  final String category;
  final DateTime createdAt;

  DealModel({
    required this.id,
    required this.shopId,
    this.shopName = '',
    this.shopLogo = '',
    this.shopAddress = '',
    required this.ownerId,
    required this.title,
    this.description = '',
    this.image = '',
    this.originalPrice = 0,
    this.dealPrice = 0,
    this.discountPercent = 0,
    required this.expiresAt,
    this.isActive = true,
    this.engagementCount = 0,
    this.savedBy = const [],
    this.category = 'general',
    required this.createdAt,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    final shop = json['shopId'];
    return DealModel(
      id: json['_id'] ?? '',
      shopId: shop is Map ? (shop['_id'] ?? '') : (shop ?? ''),
      shopName: shop is Map ? (shop['shopName'] ?? '') : '',
      shopLogo: shop is Map ? (shop['logo'] ?? '') : '',
      shopAddress: shop is Map ? (shop['address'] ?? '') : '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      dealPrice: (json['dealPrice'] ?? 0).toDouble(),
      discountPercent: json['discountPercent'] ?? 0,
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      engagementCount: json['engagementCount'] ?? 0,
      savedBy: json['savedBy'] != null ? List<String>.from(json['savedBy']) : [],
      category: json['category'] ?? 'general',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool isSavedBy(String userId) => savedBy.contains(userId);
}
