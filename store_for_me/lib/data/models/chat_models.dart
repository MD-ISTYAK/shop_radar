import '../../core/constants/app_constants.dart';

class ConversationModel {
  final String conversationId;
  final ChatUserModel? otherUser;
  final ChatShopModel? shop;
  final LastMessageModel lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.conversationId,
    this.otherUser,
    this.shop,
    required this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversationId'] ?? '',
      otherUser: json['otherUser'] != null ? ChatUserModel.fromJson(json['otherUser']) : null,
      shop: json['shop'] != null ? ChatShopModel.fromJson(json['shop']) : null,
      lastMessage: LastMessageModel.fromJson(json['lastMessage'] ?? {}),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class ChatUserModel {
  final String id;
  final String name;
  final String username;
  final String profilePic;
  final String phone;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUserModel({
    required this.id,
    required this.name,
    this.username = '',
    this.profilePic = '',
    this.phone = '',
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      profilePic: json['profilePic'] ?? json['avatar'] ?? '',
      phone: json['phone'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }

  String get displayName => username.isNotEmpty ? '@$username' : name;
  String get profilePicUrl => profilePic.isNotEmpty ? AppConstants.getImageUrl(profilePic) : '';
}

class ChatShopModel {
  final String id;
  final String shopName;
  final String logo;
  final String ownerId;

  ChatShopModel({required this.id, required this.shopName, this.logo = '', this.ownerId = ''});

  factory ChatShopModel.fromJson(Map<String, dynamic> json) {
    return ChatShopModel(
      id: json['_id'] ?? json['id'] ?? '',
      shopName: json['shopName'] ?? '',
      logo: json['logo'] ?? '',
      ownerId: json['ownerId'] ?? '',
    );
  }
}

class LastMessageModel {
  final String text;
  final DateTime createdAt;
  final bool isMine;

  LastMessageModel({this.text = '', required this.createdAt, this.isMine = false});

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isMine: json['isMine'] ?? false,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String shopId;
  final String text;
  final bool read;
  final String status; // 'sent', 'delivered', 'seen'
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName = '',
    required this.receiverId,
    required this.shopId,
    required this.text,
    this.read = false,
    this.status = 'sent',
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] is Map ? json['senderId']['_id'] ?? '' : json['senderId'] ?? '',
      senderName: json['senderId'] is Map ? json['senderId']['name'] ?? '' : '',
      receiverId: json['receiverId'] ?? '',
      shopId: json['shopId'] ?? '',
      text: json['text'] ?? '',
      read: json['read'] ?? false,
      status: json['status'] ?? 'sent',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  MessageModel copyWith({String? status}) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      shopId: shopId,
      text: text,
      read: read,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
