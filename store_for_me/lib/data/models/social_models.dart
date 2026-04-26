import '../../core/constants/app_constants.dart';

// ===================== USER PROFILE =====================
class UserProfileModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String profilePic;
  final String bio;
  final String accountType; // "user" or "shop"
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;
  final bool isVerified;
  final DateTime createdAt;

  UserProfileModel({
    required this.id,
    required this.username,
    this.name = '',
    this.email = '',
    this.profilePic = '',
    this.bio = '',
    this.accountType = 'user',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
    this.isVerified = false,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] ?? {};
    final stats = json['stats'] ?? {};
    
    return UserProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? profile['name'] ?? '',
      email: json['email'] ?? '',
      profilePic: profile['avatarUrl'] ?? json['profilePic'] ?? json['avatar'] ?? '',
      bio: profile['bio'] ?? json['bio'] ?? '',
      accountType: json['accountType'] ?? 'user',
      followersCount: stats['followersCount'] ?? json['followersCount'] ?? 0,
      followingCount: stats['followingCount'] ?? json['followingCount'] ?? 0,
      postsCount: stats['postsCount'] ?? json['postsCount'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  String get profilePicUrl => profilePic.isNotEmpty ? AppConstants.getImageUrl(profilePic) : '';
  bool get isShop => accountType == 'shop';

  UserProfileModel copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? profilePic,
    String? bio,
    String? accountType,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isFollowing,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      bio: bio ?? this.bio,
      accountType: accountType ?? this.accountType,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ===================== POST =====================
class PostModel {
  final String id;
  // Support both old shop-centric and new user-centric models
  final String shopId;
  final String shopName;
  final String shopLogo;
  final String ownerId;
  final String ownerName;
  // New user-centric fields
  final String userId;
  final String username;
  final String profilePic;
  final String accountType;
  // Content
  final String content;
  final List<String> images;
  final String mediaUrl;
  final String mediaType; // "image" or "video"
  final String type; // "post" or "reel"
  final String videoUrl;
  // Engagement
  final List<String> likes;
  final int likesCount;
  final List<CommentModel> comments;
  final int commentsCount;
  final List<String> savedBy;
  final bool isLikedByMe;
  final bool isSavedByMe;
  // Meta
  final DateTime createdAt;
  final bool isHidden;

  PostModel({
    required this.id,
    this.shopId = '',
    this.shopName = '',
    this.shopLogo = '',
    this.ownerId = '',
    this.ownerName = '',
    this.userId = '',
    this.username = '',
    this.profilePic = '',
    this.accountType = 'user',
    this.content = '',
    this.images = const [],
    this.mediaUrl = '',
    this.mediaType = 'image',
    this.type = 'post',
    this.videoUrl = '',
    this.likes = const [],
    this.likesCount = 0,
    this.comments = const [],
    this.commentsCount = 0,
    this.savedBy = const [],
    this.isLikedByMe = false,
    this.isSavedByMe = false,
    required this.createdAt,
    this.isHidden = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Handle the user field: can be a populated object or just an ID string
    String userId = '';
    String username = '';
    String profilePic = '';
    String accountType = 'user';

    final userField = json['userId'] ?? json['user'];
    if (userField is Map) {
      userId = userField['_id'] ?? userField['id'] ?? '';
      username = userField['username'] ?? userField['name'] ?? '';
      profilePic = userField['profilePic'] ?? userField['avatar'] ?? '';
      accountType = userField['accountType'] ?? 'user';
    } else if (userField is String) {
      userId = userField;
    }

    // Backward compat: shop fields
    String shopId = '';
    String shopName = '';
    String shopLogo = '';
    final shopField = json['shopId'];
    if (shopField is Map) {
      shopId = shopField['_id'] ?? '';
      shopName = shopField['shopName'] ?? '';
      shopLogo = shopField['logo'] ?? '';
    } else if (shopField is String) {
      shopId = shopField;
    }

    // Owner
    String ownerId = '';
    String ownerName = '';
    final ownerField = json['ownerId'];
    if (ownerField is Map) {
      ownerId = ownerField['_id'] ?? '';
      ownerName = ownerField['name'] ?? '';
    } else if (ownerField is String) {
      ownerId = ownerField;
    }

    // If username empty, fallback to shop or owner name
    if (username.isEmpty) username = shopName.isNotEmpty ? shopName : ownerName;
    if (profilePic.isEmpty) profilePic = shopLogo;
    if (userId.isEmpty) userId = ownerId.isNotEmpty ? ownerId : shopId;

    final userSnapshot = json['userSnapshot'];
    if (userSnapshot is Map) {
      if (username.isEmpty) username = userSnapshot['username'] ?? '';
      if (profilePic.isEmpty) profilePic = userSnapshot['avatarUrl'] ?? '';
    }

    // Parse new media array or fallback to old fields
    List<String> imagesList = [];
    String mUrl = json['mediaUrl'] ?? '';
    String mType = json['mediaType'] ?? 'image';
    String vUrl = json['videoUrl'] ?? '';
    String tUrl = json['thumbnailUrl'] ?? '';

    final mediaArray = json['media'] as List?;
    if (mediaArray != null && mediaArray.isNotEmpty) {
      for (var item in mediaArray) {
        if (item['type'] == 'image') {
          imagesList.add(item['url'] ?? '');
          if (mUrl.isEmpty) {
            mUrl = item['url'] ?? '';
            mType = 'image';
          }
        } else if (item['type'] == 'video') {
          vUrl = item['url'] ?? '';
          tUrl = item['thumbnailUrl'] ?? '';
          if (mUrl.isEmpty) {
            mUrl = item['url'] ?? '';
            mType = 'video';
          }
        }
      }
    } else {
      imagesList = (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    }

    return PostModel(
      id: json['_id'] ?? json['id'] ?? '',
      shopId: shopId,
      shopName: shopName,
      shopLogo: shopLogo,
      ownerId: ownerId,
      ownerName: ownerName,
      userId: userId,
      username: username,
      profilePic: profilePic,
      accountType: accountType,
      content: json['caption'] ?? json['content'] ?? '',
      images: imagesList,
      mediaUrl: mUrl,
      mediaType: mType,
      type: json['type'] ?? 'post',
      videoUrl: vUrl,
      likes: (json['likes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      likesCount: json['likesCount'] ?? (json['likes'] as List?)?.length ?? 0,
      comments: (json['comments'] as List?)?.map((e) => CommentModel.fromJson(e)).toList() ?? [],
      commentsCount: json['commentsCount'] ?? (json['comments'] as List?)?.length ?? 0,
      savedBy: (json['savedBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isLikedByMe: json['isLiked'] ?? json['isLikedByMe'] ?? false,
      isSavedByMe: json['isSaved'] ?? json['isSavedByMe'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isHidden: json['isHidden'] ?? false,
    );
  }

  int get likeCount => likesCount > 0 ? likesCount : likes.length;
  int get commentCount => commentsCount > 0 ? commentsCount : comments.length;
  bool isLikedBy(String userId) => isLikedByMe || likes.contains(userId);
  bool get isLiked => isLikedByMe || likes.isNotEmpty;
  bool get isReel => type == 'reel';
  bool get hasMedia => images.isNotEmpty || mediaUrl.isNotEmpty || videoUrl.isNotEmpty;
  String get displayProfilePic => profilePic.isNotEmpty ? AppConstants.getImageUrl(profilePic) : '';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  PostModel copyWith({
    int? likesCount,
    bool? isLikedByMe,
    int? commentsCount,
    bool? isSavedByMe,
    String? content,
  }) {
    return PostModel(
      id: id,
      shopId: shopId,
      shopName: shopName,
      shopLogo: shopLogo,
      ownerId: ownerId,
      ownerName: ownerName,
      userId: userId,
      username: username,
      profilePic: profilePic,
      accountType: accountType,
      content: content ?? this.content,
      images: images,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      type: type,
      videoUrl: videoUrl,
      likes: likes,
      likesCount: likesCount ?? this.likesCount,
      comments: comments,
      commentsCount: commentsCount ?? this.commentsCount,
      savedBy: savedBy,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      createdAt: createdAt,
      isHidden: isHidden,
    );
  }
}

// ===================== COMMENT =====================
class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userProfilePic;
  final String text;
  final String? parentCommentId;
  final DateTime createdAt;
  final bool isHidden;

  CommentModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userProfilePic = '',
    required this.text,
    this.parentCommentId,
    required this.createdAt,
    this.isHidden = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String userId = '';
    String userName = '';
    String userProfilePic = '';

    final userField = json['userId'] ?? json['user'];
    if (userField is Map) {
      userId = userField['_id'] ?? '';
      userName = userField['username'] ?? userField['name'] ?? '';
      userProfilePic = userField['profilePic'] ?? userField['avatar'] ?? '';
    } else if (userField is String) {
      userId = userField;
    }

    final userSnapshot = json['userSnapshot'];
    if (userSnapshot is Map) {
      if (userName.isEmpty) userName = userSnapshot['username'] ?? '';
      if (userProfilePic.isEmpty) userProfilePic = userSnapshot['avatarUrl'] ?? '';
    }

    return CommentModel(
      id: json['_id'] ?? '',
      userId: userId,
      userName: userName,
      userProfilePic: userProfilePic,
      text: json['text'] ?? '',
      parentCommentId: json['parentCommentId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isHidden: json['isHidden'] ?? false,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

// ===================== REEL =====================
class ReelModel {
  final String id;
  final String userId;
  final String username;
  final String profilePic;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final double duration;
  final bool isLikedByMe;
  final DateTime createdAt;

  ReelModel({
    required this.id,
    this.userId = '',
    this.username = '',
    this.profilePic = '',
    required this.videoUrl,
    this.thumbnailUrl = '',
    this.caption = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.duration = 0,
    this.isLikedByMe = false,
    required this.createdAt,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    String userId = '';
    String username = '';
    String profilePic = '';

    final userField = json['userId'] ?? json['user'];
    if (userField is Map) {
      userId = userField['_id'] ?? '';
      username = userField['username'] ?? userField['name'] ?? '';
      profilePic = userField['profilePic'] ?? '';
    } else if (userField is String) {
      userId = userField;
    }

    return ReelModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId,
      username: username,
      profilePic: profilePic,
      videoUrl: json['videoUrl'] ?? json['mediaUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      caption: json['caption'] ?? json['content'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      duration: (json['duration'] ?? 0).toDouble(),
      isLikedByMe: json['isLiked'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  ReelModel copyWith({int? likesCount, bool? isLikedByMe}) {
    return ReelModel(
      id: id,
      userId: userId,
      username: username,
      profilePic: profilePic,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      duration: duration,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt,
    );
  }
}

// ===================== STORY =====================
class StoryGroupModel {
  final String userId;
  final String username;
  final String profilePic;
  final List<StoryModel> stories;
  final bool hasUnseenStories;

  // Backward compat
  ShopInfo get shop => ShopInfo(id: userId, shopName: username, logo: profilePic);

  StoryGroupModel({
    this.userId = '',
    this.username = '',
    this.profilePic = '',
    required this.stories,
    this.hasUnseenStories = true,
  });

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    // New user-centric format
    String userId = '';
    String username = '';
    String profilePic = '';

    final userField = json['user'] ?? json['shop'];
    if (userField is Map) {
      userId = userField['_id'] ?? userField['id'] ?? '';
      username = userField['username'] ?? userField['shopName'] ?? userField['name'] ?? '';
      profilePic = userField['profilePic'] ?? userField['logo'] ?? '';
    }

    // Direct fields override
    if (json['userId'] is String) userId = json['userId'];

    return StoryGroupModel(
      userId: userId,
      username: username,
      profilePic: profilePic,
      stories: (json['stories'] as List?)?.map((e) => StoryModel.fromJson(e)).toList() ?? [],
      hasUnseenStories: json['hasUnseen'] ?? true,
    );
  }

  String get displayProfilePic => profilePic.isNotEmpty ? AppConstants.getImageUrl(profilePic) : '';
}

class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType; // "image" or "video"
  final String caption;
  final List<String> viewers;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isHidden;

  // Backward compat
  String get shopId => userId;
  String get imageUrl => mediaUrl;

  StoryModel({
    required this.id,
    this.userId = '',
    required this.mediaUrl,
    this.mediaType = 'image',
    this.caption = '',
    this.viewers = const [],
    required this.createdAt,
    required this.expiresAt,
    this.isHidden = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? json['shopId'] ?? '',
      mediaUrl: json['mediaUrl'] ?? json['imageUrl'] ?? '',
      mediaType: json['mediaType'] ?? 'image',
      caption: json['caption'] ?? '',
      viewers: (json['viewers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now().add(const Duration(hours: 24)),
      isHidden: json['isHidden'] ?? false,
    );
  }

  bool get isVideo => mediaType == 'video';
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  String get displayMediaUrl => mediaUrl.isNotEmpty ? AppConstants.getImageUrl(mediaUrl) : '';
}

// ===================== BACKWARD COMPAT =====================
class ShopInfo {
  final String id;
  final String shopName;
  final String logo;

  ShopInfo({required this.id, required this.shopName, this.logo = ''});

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    return ShopInfo(
      id: json['_id'] ?? json['id'] ?? '',
      shopName: json['shopName'] ?? json['username'] ?? '',
      logo: json['logo'] ?? json['profilePic'] ?? '',
    );
  }
}
