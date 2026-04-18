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
  final List<String> images;
  final String openingTime;
  final String closingTime;
  final List<String> operatingDays;
  final String phone;
  final String whatsappNumber;
  final String website;
  final String status;
  final String crowdLevel;
  final bool is24x7;
  final bool isEmergency;
  final String emergencyType;
  final List<String> features;
  final bool queueEnabled;
  final double rating;
  final int totalRatings;
  final int followers;
  final int totalCheckIns;
  final int totalOrders;
  final double trendingScore;
  final bool isTrending;
  final bool isVerified;
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
    this.images = const [],
    required this.openingTime,
    required this.closingTime,
    this.operatingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    required this.phone,
    this.whatsappNumber = '',
    this.website = '',
    this.status = 'open',
    this.crowdLevel = 'low',
    this.is24x7 = false,
    this.isEmergency = false,
    this.emergencyType = '',
    this.features = const [],
    this.queueEnabled = false,
    this.rating = 0,
    this.totalRatings = 0,
    this.followers = 0,
    this.totalCheckIns = 0,
    this.totalOrders = 0,
    this.trendingScore = 0,
    this.isTrending = false,
    this.isVerified = false,
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
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      openingTime: json['openingTime'] ?? '',
      closingTime: json['closingTime'] ?? '',
      operatingDays: json['operatingDays'] != null
          ? List<String>.from(json['operatingDays'])
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      phone: json['phone'] ?? '',
      whatsappNumber: json['whatsappNumber'] ?? '',
      website: json['website'] ?? '',
      status: json['status'] ?? 'open',
      crowdLevel: json['crowdLevel'] ?? 'low',
      is24x7: json['is24x7'] ?? false,
      isEmergency: json['isEmergency'] ?? false,
      emergencyType: json['emergencyType'] ?? '',
      features: json['features'] != null ? List<String>.from(json['features']) : [],
      queueEnabled: json['queueEnabled'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      followers: json['followers'] ?? 0,
      totalCheckIns: json['totalCheckIns'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      trendingScore: (json['trendingScore'] ?? 0).toDouble(),
      isTrending: json['isTrending'] ?? false,
      isVerified: json['isVerified'] ?? false,
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
        'whatsappNumber': whatsappNumber,
        'is24x7': is24x7,
        'queueEnabled': queueEnabled,
        'features': features,
        'operatingDays': operatingDays,
      };

  bool get isOpen {
    if (is24x7) return true;
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
    if (is24x7) return 'Open 24×7';
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

  String get crowdEmoji {
    switch (crowdLevel) {
      case 'low': return '🟢';
      case 'medium': return '🟡';
      case 'high': return '🔴';
      default: return '⚪';
    }
  }

  String get whatsappLink {
    final number = whatsappNumber.isNotEmpty ? whatsappNumber : phone;
    return 'https://wa.me/91$number?text=Hi, I found your shop on Shop Radar. I\'d like to enquire.';
  }

  bool get hasWhatsApp => whatsappNumber.isNotEmpty || phone.isNotEmpty;
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
