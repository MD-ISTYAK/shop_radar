class BusinessModel {
  final String id;
  final String userId;
  final String businessType;
  final String businessName;
  final String description;
  final String category;
  final String status;
  final String? shopRefId;
  final String? deliveryPartnerRefId;
  final String serviceArea;
  final String contactPhone;
  final String logo;
  final bool isActive;
  final DateTime? createdAt;

  // Populated sub-objects (from API response)
  final Map<String, dynamic>? shopDetails;
  final Map<String, dynamic>? deliveryPartnerDetails;

  BusinessModel({
    required this.id,
    required this.userId,
    required this.businessType,
    required this.businessName,
    this.description = '',
    this.category = '',
    this.status = 'active',
    this.shopRefId,
    this.deliveryPartnerRefId,
    this.serviceArea = '',
    this.contactPhone = '',
    this.logo = '',
    this.isActive = true,
    this.createdAt,
    this.shopDetails,
    this.deliveryPartnerDetails,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    // shopRef can be a string ID or a populated object
    String? shopId;
    Map<String, dynamic>? shopData;
    if (json['shopRef'] is Map) {
      shopData = json['shopRef'] as Map<String, dynamic>;
      shopId = shopData['_id'] ?? '';
    } else if (json['shopRef'] is String) {
      shopId = json['shopRef'];
    }

    String? dpId;
    Map<String, dynamic>? dpData;
    if (json['deliveryPartnerRef'] is Map) {
      dpData = json['deliveryPartnerRef'] as Map<String, dynamic>;
      dpId = dpData['_id'] ?? '';
    } else if (json['deliveryPartnerRef'] is String) {
      dpId = json['deliveryPartnerRef'];
    }

    return BusinessModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? (json['userId']['_id'] ?? '') : (json['userId'] ?? ''),
      businessType: json['businessType'] ?? '',
      businessName: json['businessName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'active',
      shopRefId: shopId,
      deliveryPartnerRefId: dpId,
      serviceArea: json['serviceArea'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      logo: json['logo'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      shopDetails: shopData,
      deliveryPartnerDetails: dpData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    '_id': id,
    'userId': userId,
    'businessType': businessType,
    'businessName': businessName,
    'description': description,
    'category': category,
    'status': status,
    'shopRef': shopRefId,
    'deliveryPartnerRef': deliveryPartnerRefId,
    'serviceArea': serviceArea,
    'contactPhone': contactPhone,
    'logo': logo,
    'isActive': isActive,
  };

  bool get isShop => businessType == 'shop';
  bool get isDeliveryPartner => businessType == 'delivery_partner';
  bool get isCartService => businessType == 'cart_service';
  bool get isFreelancer => businessType == 'freelancer';

  String get typeDisplayName {
    switch (businessType) {
      case 'shop': return 'Shop';
      case 'cart_service': return 'Cart Service';
      case 'delivery_partner': return 'Delivery Partner';
      case 'freelancer': return 'Freelancer';
      case 'other': return 'Other';
      default: return businessType;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'active': return 'Active';
      case 'pending': return 'Pending';
      case 'suspended': return 'Suspended';
      default: return status;
    }
  }
}
