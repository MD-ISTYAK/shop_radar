import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchConversations());
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);

    final currentUserId = authState.user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: chatState.isLoading
          ? const LoadingIndicator()
          : chatState.conversations.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.chat_bubble_outline,
                  title: 'No conversations',
                  subtitle: 'Start a chat from any shop\'s page',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(chatProvider.notifier).fetchConversations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatState.conversations.length,
                    itemBuilder: (context, index) {
                      final conv = chatState.conversations[index];
                      final isShopOwner = conv.shop?.ownerId == currentUserId;
                      final title = isShopOwner 
                          ? (conv.otherUser?.name ?? 'Customer')
                          : (conv.shop?.shopName ?? 'Shop');

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: conv.unreadCount > 0 ? AppColors.primaryLight.withAlpha(10) : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: conv.unreadCount > 0 ? Border.all(color: AppColors.primary.withAlpha(30)) : null,
                          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryLight.withAlpha(30),
                            child: conv.shop != null && conv.shop!.logo.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: '${AppConstants.uploadsUrl}${conv.shop!.logo}',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.store, color: AppColors.primary),
                                    ),
                                  )
                                : const Icon(Icons.store, color: AppColors.primary),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat.MMMd().format(conv.lastMessage.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conv.lastMessage.isMine
                                      ? 'You: ${conv.lastMessage.text}'
                                      : conv.lastMessage.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: conv.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                    fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (conv.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${conv.unreadCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/chat', arguments: {
                              'conversationId': conv.conversationId,
                              'receiverId': conv.otherUser?.id ?? '',
                              'shopId': conv.shop?.id ?? '',
                              'title': title,
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
