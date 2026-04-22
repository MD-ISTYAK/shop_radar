import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_models.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class ChatState {
  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final bool isLoading;
  final String? currentConversationId;

  const ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoading = false,
    this.currentConversationId,
  });

  ChatState copyWith({
    List<ConversationModel>? conversations,
    List<MessageModel>? messages,
    bool? isLoading,
    String? currentConversationId,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentConversationId: currentConversationId ?? this.currentConversationId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();

  ChatNotifier() : super(const ChatState()) {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socket.onNewMessage((data) {
      final message = MessageModel.fromJson(data);
      
      // If we are currently in this conversation, add it to the message list
      if (state.currentConversationId == message.conversationId) {
        state = state.copyWith(messages: [...state.messages, message]);
        // Notify sender that we received it
        _socket.emitMessageReceived(message.id, message.senderId);
      }
      
      // Update the last message in the conversation list
      final updatedConversations = state.conversations.map((conv) {
        if (conv.conversationId == message.conversationId) {
          return ConversationModel(
            conversationId: conv.conversationId,
            otherUser: conv.otherUser,
            shop: conv.shop,
            unreadCount: (state.currentConversationId == message.conversationId) 
              ? conv.unreadCount : conv.unreadCount + 1,
            lastMessage: LastMessageModel(
              text: message.text,
              createdAt: message.createdAt,
              isMine: false,
            ),
          );
        }
        return conv;
      }).toList();
      
      state = state.copyWith(conversations: updatedConversations);
    });

    _socket.onMessageStatusUpdate((data) {
      // data: { messageId, status, conversationId }
      final messageId = data['messageId'];
      final conversationId = data['conversationId'];
      final status = data['status'];

      if (conversationId != null && status == 'seen') {
        // Mark all messages in this conversation as seen
        final updatedMessages = state.messages.map((m) {
          if (m.senderId != null && m.status != 'seen') { // usually only our own messages are updated here
             return m.copyWith(status: 'seen');
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updatedMessages);
      } else if (messageId != null) {
        // Update specific message
        final updatedMessages = state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(status: status);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updatedMessages);
      }
    });

    _socket.onUserStatusChange((data) {
      // data: { userId, isOnline, lastSeen }
      final userId = data['userId'];
      final isOnline = data['isOnline'];
      final lastSeenStr = data['lastSeen'];
      final lastSeen = lastSeenStr != null ? DateTime.parse(lastSeenStr) : DateTime.now();

      final updatedConversations = state.conversations.map((conv) {
        if (conv.otherUser?.id == userId) {
          return ConversationModel(
            conversationId: conv.conversationId,
            otherUser: ChatUserModel(
              id: conv.otherUser!.id,
              name: conv.otherUser!.name,
              phone: conv.otherUser!.phone,
              isOnline: isOnline,
              lastSeen: lastSeen,
            ),
            shop: conv.shop,
            lastMessage: conv.lastMessage,
            unreadCount: conv.unreadCount,
          );
        }
        return conv;
      }).toList();

      state = state.copyWith(conversations: updatedConversations);
    });
  }

  Future<void> fetchConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getConversations();
      if (response.data['success'] == true) {
        final conversations = (response.data['data'] as List)
            .map((e) => ConversationModel.fromJson(e))
            .toList();
        state = state.copyWith(conversations: conversations, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    state = state.copyWith(isLoading: true, currentConversationId: conversationId);
    try {
      final response = await _api.getChatMessages(conversationId);
      if (response.data['success'] == true) {
        final messages = (response.data['data'] as List)
            .map((e) => MessageModel.fromJson(e))
            .toList();
        state = state.copyWith(messages: messages, isLoading: false);
        
        // Emit seen event if there are messages from other user
        if (messages.isNotEmpty) {
           final lastMsg = messages.last;
           // If last message is from other participant and not seen yet
           // (Simple logic: mark entire conversation as seen when opened)
           _socket.emitMessageSeen(conversationId, lastMsg.senderId);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(String receiverId, String? shopId, String text) async {
    try {
      final response = await _api.sendChatMessage(receiverId, shopId, text);
      if (response.data['success'] == true) {
        final message = MessageModel.fromJson(response.data['data']);
        state = state.copyWith(messages: [...state.messages, message]);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> startConversation(String shopId) async {
    try {
      final response = await _api.startChatConversation(shopId);
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
