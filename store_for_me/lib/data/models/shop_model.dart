class ShopModel {
  final String id;
  final String shopName;
  final String ownerId;
  final String category;
  final String description;
  final String address;
  final LocationModel? location;
  final String logo;
  final String banner;
  final String openingTime;
  final String closingTime;
  final String phone;
  final String status;
  final String crowdLevel;
  final double rating;
  final int totalRatings;
  final double? distance;
  final String? distanceFormatted;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.ownerId,
    required this.category,
    this.description = '',
    required this.address,
    this.location,
    this.logo = '',
    this.banner = '',
    required this.openingTime,
    required this.closingTime,
    required this.phone,
    this.status = 'open',
    this.crowdLevel = 'low',
    this.rating = 0,
    this.totalRatings = 0,
    this.distance,
    this.distanceFormatted,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['_id'] ?? json['id'] ?? '',
      shopName: json['shopName'] ?? '',
      ownerId: json['ownerId'] is Map ? json['ownerId']['_id'] ?? '' : json['ownerId'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      location: json['location'] != null ? LocationModel.fromJson(json['location']) : null,
      logo: json['logo'] ?? '',
      banner: json['banner'] ?? '',
      openingTime: json['openingTime'] ?? '',
      closingTime: json['closingTime'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'open',
      crowdLevel: json['crowdLevel'] ?? 'low',
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      distance: json['distance']?.toDouble(),
      distanceFormatted: json['distanceFormatted'],
    );
  }

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'category': category,
        'description': description,
        'address': address,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'phone': phone,
      };

  bool get isOpen {
    if (status == 'closed' || status == 'temporarily_closed') return false;
    if (status != 'open' && status != 'busy') return false;

    try {
      if (openingTime.isEmpty || closingTime.isEmpty) return true;

      final now = DateTime.now();

      final openParts = openingTime.split(':');
      final openDateTime = DateTime(now.year, now.month, now.day, int.parse(openParts[0]), int.parse(openParts[1]));

      final closeParts = closingTime.split(':');
      final closeDateTime = DateTime(now.year, now.month, now.day, int.parse(closeParts[0]), int.parse(closeParts[1]));

      return now.isAfter(openDateTime) && now.isBefore(closeDateTime);
    } catch (e) {
      return status == 'open' || status == 'busy';
    }
  }

  bool get isBusy => status == 'busy';
  bool get isTemporarilyClosed => status == 'temporarily_closed';

  String get statusLabel {
    switch (status) {
      case 'open': return 'Open';
      case 'closed': return 'Closed';
      case 'busy': return 'Busy';
      case 'temporarily_closed': return 'Temporarily Closed';
      default: return status;
    }
  }

  String get crowdLabel {
    switch (crowdLevel) {
      case 'low': return 'Not Crowded';
      case 'medium': return 'Moderate';
      case 'high': return 'Very Crowded';
      default: return crowdLevel;
    }
  }
}

class LocationModel {
  final String type;
  final List<double> coordinates;

  LocationModel({this.type = 'Point', required this.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [0, 0],
    );
  }

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0;
}
