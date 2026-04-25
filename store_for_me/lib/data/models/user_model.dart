class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String avatar;
  final List<double> coordinates;
  final List<String> interests;
  final String language;
  final String referralCode;
  final String referredBy;
  final bool isVerified;
  final bool profileComplete;
  final int totalCheckIns;
  final int totalReviews;
  final int totalOrders;
  final String username;
  final String bio;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.avatar = '',
    this.coordinates = const [0, 0],
    this.interests = const [],
    this.language = 'en',
    this.referralCode = '',
    this.referredBy = '',
    this.isVerified = false,
    this.profileComplete = false,
    this.totalCheckIns = 0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.username = '',
    this.bio = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'];
    final profile = json['profile'] ?? {};
    
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? profile['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      avatar: json['avatar'] ?? profile['avatarUrl'] ?? '',
      coordinates: loc != null && loc['coordinates'] != null
          ? List<double>.from(loc['coordinates'].map((e) => (e as num).toDouble()))
          : [0, 0],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      language: json['language'] ?? 'en',
      referralCode: json['referralCode'] ?? '',
      referredBy: json['referredBy'] ?? '',
      isVerified: json['isVerified'] ?? false,
      profileComplete: json['profileComplete'] ?? false,
      totalReviews: json['totalReviews'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      username: json['username'] ?? '',
      bio: json['bio'] ?? profile['bio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    '_id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar': avatar,
    'interests': interests,
    'language': language,
    'username': username,
    'bio': bio,
  };

  bool get isOwner => role == 'owner';
  bool get isDeliveryPartner => role == 'delivery_partner';
}
