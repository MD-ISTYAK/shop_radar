class PostModel {
  final String id;
  final String userId;
  final String caption;
  final String type;
  final List<MediaModel> media;
  final UserSnapshot userSnapshot;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isHidden;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.caption,
    required this.type,
    required this.media,
    required this.userSnapshot,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isHidden,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      caption: json['caption'] ?? json['content'] ?? '',
      type: json['type'] ?? 'post',
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => MediaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          _parseLegacyMedia(json),
      userSnapshot: UserSnapshot.fromJson(json['userSnapshot'] ?? {}),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isHidden: json['isHidden'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  // Helper to handle legacy backward-compatible fields in MongoDB
  static List<MediaModel> _parseLegacyMedia(Map<String, dynamic> json) {
    List<MediaModel> mediaList = [];
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      for (var url in json['images']) {
        mediaList.add(MediaModel(url: url, type: 'image'));
      }
    } else if (json['mediaUrl'] != null && json['mediaUrl'].toString().isNotEmpty) {
      mediaList.add(MediaModel(url: json['mediaUrl'], type: json['mediaType'] ?? 'image'));
    } else if (json['videoUrl'] != null && json['videoUrl'].toString().isNotEmpty) {
       mediaList.add(MediaModel(
           url: json['videoUrl'], 
           type: 'video', 
           thumbnailUrl: json['thumbnailUrl']));
    }
    return mediaList;
  }
}

class MediaModel {
  final String url;
  final String type;
  final String? thumbnailUrl;

  MediaModel({required this.url, required this.type, this.thumbnailUrl});

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}

class UserSnapshot {
  final String username;
  final String avatarUrl;

  UserSnapshot({required this.username, required this.avatarUrl});

  factory UserSnapshot.fromJson(Map<String, dynamic> json) {
    return UserSnapshot(
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}
