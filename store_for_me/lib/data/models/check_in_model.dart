class CheckInModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String shopId;
  final String shopName;
  final String shopLogo;
  final int? microRating;
  final int loyaltyPointsEarned;
  final DateTime createdAt;

  CheckInModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userAvatar = '',
    required this.shopId,
    this.shopName = '',
    this.shopLogo = '',
    this.microRating,
    this.loyaltyPointsEarned = 5,
    required this.createdAt,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final shop = json['shopId'];
    return CheckInModel(
      id: json['_id'] ?? '',
      userId: user is Map ? (user['_id'] ?? '') : (user ?? ''),
      userName: user is Map ? (user['name'] ?? '') : '',
      userAvatar: user is Map ? (user['avatar'] ?? '') : '',
      shopId: shop is Map ? (shop['_id'] ?? '') : (shop ?? ''),
      shopName: shop is Map ? (shop['shopName'] ?? '') : '',
      shopLogo: shop is Map ? (shop['logo'] ?? '') : '',
      microRating: json['microRating'],
      loyaltyPointsEarned: json['loyaltyPointsEarned'] ?? 5,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
