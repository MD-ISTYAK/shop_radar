class TokenModel {
  final String id;
  final String shopId;
  final String shopName;
  final String userId;
  final int tokenNumber;
  final String status;
  final int estimatedWaitMinutes;
  final int positionInQueue;
  final DateTime createdAt;

  TokenModel({
    required this.id,
    required this.shopId,
    this.shopName = '',
    required this.userId,
    required this.tokenNumber,
    this.status = 'waiting',
    this.estimatedWaitMinutes = 0,
    this.positionInQueue = 0,
    required this.createdAt,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      id: json['_id'] ?? json['id'] ?? '',
      shopId: json['shopId'] is Map ? json['shopId']['_id'] ?? '' : json['shopId'] ?? '',
      shopName: json['shopId'] is Map ? json['shopId']['shopName'] ?? '' : '',
      userId: json['userId'] ?? '',
      tokenNumber: json['tokenNumber'] ?? 0,
      status: json['status'] ?? 'waiting',
      estimatedWaitMinutes: json['estimatedWaitMinutes'] ?? 0,
      positionInQueue: json['positionInQueue'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  bool get isActive => status == 'waiting' || status == 'serving';
  bool get isServing => status == 'serving';
  bool get isWaiting => status == 'waiting';
}

class QueueStatusModel {
  final int currentlyServing;
  final int waitingCount;
  final int estimatedWaitMinutes;

  QueueStatusModel({
    this.currentlyServing = 0,
    this.waitingCount = 0,
    this.estimatedWaitMinutes = 0,
  });

  factory QueueStatusModel.fromJson(Map<String, dynamic> json) {
    return QueueStatusModel(
      currentlyServing: json['currentlyServing'] ?? 0,
      waitingCount: json['waitingCount'] ?? 0,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] ?? 0,
    );
  }
}
