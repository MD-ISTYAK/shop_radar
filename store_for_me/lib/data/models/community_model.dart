class CommunityQuestionModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final String area;
  final List<String> tags;
  final List<AnswerModel> answers;
  final bool isResolved;
  final int viewCount;
  final DateTime createdAt;

  CommunityQuestionModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userAvatar = '',
    required this.text,
    this.area = '',
    this.tags = const [],
    this.answers = const [],
    this.isResolved = false,
    this.viewCount = 0,
    required this.createdAt,
  });

  factory CommunityQuestionModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    return CommunityQuestionModel(
      id: json['_id'] ?? '',
      userId: user is Map ? (user['_id'] ?? '') : (user ?? ''),
      userName: user is Map ? (user['name'] ?? '') : '',
      userAvatar: user is Map ? (user['avatar'] ?? '') : '',
      text: json['text'] ?? '',
      area: json['area'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      answers: json['answers'] != null
          ? (json['answers'] as List).map((a) => AnswerModel.fromJson(a)).toList()
          : [],
      isResolved: json['isResolved'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  int get answerCount => answers.length;
}

class AnswerModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final String? shopMentionedId;
  final String? shopMentionedName;
  final List<String> upvotes;
  final DateTime createdAt;

  AnswerModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userAvatar = '',
    required this.text,
    this.shopMentionedId,
    this.shopMentionedName,
    this.upvotes = const [],
    required this.createdAt,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final shop = json['shopMentioned'];
    return AnswerModel(
      id: json['_id'] ?? '',
      userId: user is Map ? (user['_id'] ?? '') : (user ?? ''),
      userName: user is Map ? (user['name'] ?? '') : '',
      userAvatar: user is Map ? (user['avatar'] ?? '') : '',
      text: json['text'] ?? '',
      shopMentionedId: shop is Map ? shop['_id'] : null,
      shopMentionedName: shop is Map ? shop['shopName'] : null,
      upvotes: json['upvotes'] != null ? List<String>.from(json['upvotes']) : [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  int get upvoteCount => upvotes.length;
}
