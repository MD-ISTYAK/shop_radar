class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String shopId;
  final int rating;
  final String text;
  final List<String> images;
  final List<String> upvotes;
  final OwnerReply? ownerReply;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.shopId,
    required this.rating,
    this.text = '',
    this.images = const [],
    this.upvotes = const [],
    this.ownerReply,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    return ReviewModel(
      id: json['_id'] ?? '',
      userId: user is Map ? (user['_id'] ?? '') : (user ?? ''),
      userName: user is Map ? (user['name'] ?? '') : '',
      userAvatar: user is Map ? (user['avatar'] ?? '') : '',
      shopId: json['shopId'] ?? '',
      rating: json['rating'] ?? 0,
      text: json['text'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      upvotes: json['upvotes'] != null ? List<String>.from(json['upvotes']) : [],
      ownerReply: json['ownerReply'] != null && json['ownerReply']['text'] != null && json['ownerReply']['text'].isNotEmpty
          ? OwnerReply.fromJson(json['ownerReply'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  int get upvoteCount => upvotes.length;
  bool isUpvotedBy(String userId) => upvotes.contains(userId);
}

class OwnerReply {
  final String text;
  final DateTime? repliedAt;

  OwnerReply({required this.text, this.repliedAt});

  factory OwnerReply.fromJson(Map<String, dynamic> json) {
    return OwnerReply(
      text: json['text'] ?? '',
      repliedAt: json['repliedAt'] != null ? DateTime.tryParse(json['repliedAt']) : null,
    );
  }
}
