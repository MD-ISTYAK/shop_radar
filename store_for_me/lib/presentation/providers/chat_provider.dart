import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_models.dart';
import '../../services/api_service.dart';

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

  ChatNotifier() : super(const ChatState());

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
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> sendMessage(String receiverId, String shopId, String text) async {
    try {
      final response = await _api.sendChatMessage(receiverId, shopId, text);
      if (response.data['success'] == true) {
        final message = MessageModel.fromJson(response.data['data']);
        state = state.copyWith(messages: [...state.messages, message]);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
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
