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
  final String phone;

  ChatUserModel({required this.id, required this.name, this.phone = ''});

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
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
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
