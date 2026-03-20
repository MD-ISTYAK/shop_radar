class PostModel {
  final String id;
  final String shopId;
  final String shopName;
  final String shopLogo;
  final String ownerId;
  final String ownerName;
  final String content;
  final List<String> images;
  final String type; // post or reel
  final String videoUrl;
  final List<String> likes;
  final List<CommentModel> comments;
  final DateTime createdAt;
  final bool isHidden;

  PostModel({
    required this.id,
    required this.shopId,
    this.shopName = '',
    this.shopLogo = '',
    required this.ownerId,
    this.ownerName = '',
    this.content = '',
    this.images = const [],
    this.type = 'post',
    this.videoUrl = '',
    this.likes = const [],
    this.comments = const [],
    required this.createdAt,
    this.isHidden = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id'] ?? json['id'] ?? '',
      shopId: json['shopId'] is Map ? json['shopId']['_id'] ?? '' : json['shopId'] ?? '',
      shopName: json['shopId'] is Map ? json['shopId']['shopName'] ?? '' : '',
      shopLogo: json['shopId'] is Map ? json['shopId']['logo'] ?? '' : '',
      ownerId: json['ownerId'] is Map ? json['ownerId']['_id'] ?? '' : json['ownerId'] ?? '',
      ownerName: json['ownerId'] is Map ? json['ownerId']['name'] ?? '' : '',
      content: json['content'] ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      type: json['type'] ?? 'post',
      videoUrl: json['videoUrl'] ?? '',
      likes: (json['likes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      comments: (json['comments'] as List?)?.map((e) => CommentModel.fromJson(e)).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isHidden: json['isHidden'] ?? false,
    );
  }

  int get likesCount => likes.length;
  int get commentsCount => comments.length;
  bool isLikedBy(String userId) => likes.contains(userId);
  bool get isReel => type == 'reel';
}

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final bool isHidden;

  CommentModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.text,
    required this.createdAt,
    this.isHidden = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? '',
      userName: json['userId'] is Map ? json['userId']['name'] ?? '' : '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isHidden: json['isHidden'] ?? false,
    );
  }
}

class StoryGroupModel {
  final ShopInfo shop;
  final List<StoryModel> stories;

  StoryGroupModel({required this.shop, required this.stories});

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    return StoryGroupModel(
      shop: ShopInfo.fromJson(json['shop']),
      stories: (json['stories'] as List?)?.map((e) => StoryModel.fromJson(e)).toList() ?? [],
    );
  }
}

class StoryModel {
  final String id;
  final String shopId;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isHidden;

  StoryModel({
    required this.id,
    required this.shopId,
    required this.imageUrl,
    this.caption = '',
    required this.createdAt,
    required this.expiresAt,
    this.isHidden = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['_id'] ?? '',
      shopId: json['shopId'] is Map ? json['shopId']['_id'] ?? '' : json['shopId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      caption: json['caption'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now(),
      isHidden: json['isHidden'] ?? false,
    );
  }
}

class ShopInfo {
  final String id;
  final String shopName;
  final String logo;

  ShopInfo({required this.id, required this.shopName, this.logo = ''});

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    return ShopInfo(
      id: json['_id'] ?? json['id'] ?? '',
      shopName: json['shopName'] ?? '',
      logo: json['logo'] ?? '',
    );
  }
}
