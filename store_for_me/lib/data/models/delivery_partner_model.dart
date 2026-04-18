class DeliveryPartnerModel {
  final String id;
  final String userId;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final String kycStatus;
  final bool isOnline;
  final List<double> coordinates;
  final String? activeDeliveryId;
  final int totalDeliveries;
  final double rating;
  final double earningsBalance;
  final double totalEarnings;

  DeliveryPartnerModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    this.vehicleNumber = '',
    this.licenseNumber = '',
    this.kycStatus = 'pending',
    this.isOnline = false,
    this.coordinates = const [0, 0],
    this.activeDeliveryId,
    this.totalDeliveries = 0,
    this.rating = 5.0,
    this.earningsBalance = 0,
    this.totalEarnings = 0,
  });

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    final loc = json['currentLocation'];
    return DeliveryPartnerModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      vehicleType: json['vehicleType'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      kycStatus: json['kycStatus'] ?? 'pending',
      isOnline: json['isOnline'] ?? false,
      coordinates: loc != null && loc['coordinates'] != null
          ? List<double>.from(loc['coordinates'].map((e) => (e as num).toDouble()))
          : [0, 0],
      activeDeliveryId: json['activeDeliveryId'] is Map
          ? json['activeDeliveryId']['_id']
          : json['activeDeliveryId'],
      totalDeliveries: json['totalDeliveries'] ?? 0,
      rating: (json['rating'] ?? 5.0).toDouble(),
      earningsBalance: (json['earningsBalance'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
    );
  }

  bool get isKYCVerified => kycStatus == 'verified';
  bool get hasActiveDelivery => activeDeliveryId != null;
}
