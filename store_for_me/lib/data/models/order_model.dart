import 'delivery_model.dart';

class OrderModel {
  final String id;
  final String orderId;
  final String userId;
  final String shopId;
  final String shopName;
  final String shopLogo;
  final String shopPhone;
  final List<DeliveryItemModel> items; // Reuse from delivery_model
  final double totalAmount;
  final double deliveryFee;
  final String status;
  final String deliveryType;
  final String userOtp;
  final String pickupCode;
  final String qrCodeData;
  final List<dynamic> packedImages;
  final List<dynamic> deliveredImages;
  final List<TimelineEvent> timeline;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final Map<String, dynamic>? deliveryPartner;

  OrderModel({
    required this.id,
    this.orderId = '',
    required this.userId,
    required this.shopId,
    this.shopName = '',
    this.shopLogo = '',
    this.shopPhone = '',
    this.items = const [],
    this.totalAmount = 0,
    this.deliveryFee = 0,
    this.status = 'pending',
    this.deliveryType = 'home_delivery',
    this.userOtp = '',
    this.pickupCode = '',
    this.qrCodeData = '',
    this.packedImages = const [],
    this.deliveredImages = const [],
    this.timeline = const [],
    this.deliveryAddress = '',
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    required this.createdAt,
    this.deliveryPartner,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      shopId: json['shopId'] is Map ? json['shopId']['_id'] : (json['shopId'] ?? ''),
      shopName: json['shopId'] is Map ? json['shopId']['shopName'] ?? '' : '',
      shopLogo: json['shopId'] is Map ? json['shopId']['logo'] ?? '' : '',
      shopPhone: json['shopId'] is Map ? json['shopId']['phone'] ?? '' : '',
      items: (json['items'] as List?)?.map((e) => DeliveryItemModel.fromJson(e)).toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      deliveryType: json['deliveryType'] ?? 'home_delivery',
      userOtp: json['userOtp'] ?? '',
      pickupCode: json['pickupCode'] ?? '',
      qrCodeData: json['qrCodeData'] ?? '',
      packedImages: json['packedImages'] ?? [],
      deliveredImages: json['deliveredImages'] ?? [],
      timeline: (json['timeline'] as List?)?.map((e) => TimelineEvent.fromJson(e)).toList() ?? [],
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'cod',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      deliveryPartner: json['deliveryPartnerId'] is Map ? json['deliveryPartnerId'] : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'packed': return 'Packed';
      case 'ready': return 'Ready';
      case 'delivery_assigned': return 'Assigned';
      case 'picked_up': return 'Picked Up';
      case 'out_for_delivery': return 'Out For Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  bool get isCompleted => status == 'delivered' || status == 'cancelled';

  String get shortId => id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
}

class TimelineEvent {
  final String status;
  final DateTime timestamp;
  final String note;

  TimelineEvent({
    required this.status,
    required this.timestamp,
    required this.note,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      note: json['note'] ?? '',
    );
  }
}
