class DeliveryPartnerModel {
  final String id;
  final String userId;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final String kycStatus;
  final bool isOnline;
  final List<double> coordinates;
  final List<String> activeDeliveries;
  final int completedDeliveries;
  final int rejectedDeliveries;
  final double averageDeliveryTime;
  final int totalDeliveries;
  final double rating;
  final double earningsBalance;
  final double totalEarnings;
  final double todayEarnings;
  final int totalAcceptedRequests;
  final int missedRequests;
  final int failedOrders;

  DeliveryPartnerModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    this.vehicleNumber = '',
    this.licenseNumber = '',
    this.kycStatus = 'pending',
    this.isOnline = false,
    this.coordinates = const [0, 0],
    this.activeDeliveries = const [],
    this.completedDeliveries = 0,
    this.rejectedDeliveries = 0,
    this.averageDeliveryTime = 0,
    this.totalDeliveries = 0,
    this.rating = 5.0,
    this.earningsBalance = 0,
    this.totalEarnings = 0,
    this.todayEarnings = 0,
    this.totalAcceptedRequests = 0,
    this.missedRequests = 0,
    this.failedOrders = 0,
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
      activeDeliveries: (json['activeDeliveries'] as List?)?.map((e) => e is Map ? e['_id'].toString() : e.toString()).toList() ?? [],
      completedDeliveries: json['completedDeliveries'] ?? 0,
      rejectedDeliveries: json['rejectedDeliveries'] ?? 0,
      averageDeliveryTime: (json['averageDeliveryTime'] ?? 0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      rating: (json['rating'] ?? 5.0).toDouble(),
      earningsBalance: (json['earningsBalance'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      totalAcceptedRequests: json['totalAcceptedRequests'] ?? 0,
      missedRequests: json['missedRequests'] ?? 0,
      failedOrders: json['failedOrders'] ?? 0,
    );
  }

  bool get isKYCVerified => kycStatus == 'verified';
  bool get hasActiveDelivery => activeDeliveries.isNotEmpty;
}
