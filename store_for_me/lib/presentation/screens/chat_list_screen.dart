import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_widgets.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchConversations());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // === PREMIUM HEADER ===
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Messages',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      _buildHeaderAction(Icons.edit_note_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PremiumTextField(
                    controller: _searchController,
                    hintText: 'Search messages...',
                    prefixIcon: Icons.search_rounded,
                  ),
                ],
              ),
            ),

            Expanded(
              child: chatState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chatState.conversations.isEmpty
                      ? _buildEmptyState()
                      : _buildConversationList(chatState, authState.user?.id ?? '', isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textLight.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          'No messages yet',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'Start a conversation with a shop owner.',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildConversationList(dynamic chatState, String currentUserId, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => ref.read(chatProvider.notifier).fetchConversations(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Active Contacts (Stories Style)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: chatState.conversations.length.clamp(0, 8),
                itemBuilder: (context, index) {
                  final conv = chatState.conversations[index];
                  final profilePic = conv.otherUser?.profilePicUrl ?? (conv.shop?.logo ?? '');
                  final name = conv.otherUser?.displayName ?? (conv.shop?.shopName ?? 'Shop');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            PremiumAvatar(imageUrl: profilePic, size: 56),
                            if (conv.otherUser?.isOnline == true)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 60,
                          child: Text(
                            name.split(' ').first,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Recent Chats
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final conv = chatState.conversations[index];
                  return _buildConversationItem(conv, isDark).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1);
                },
                childCount: chatState.conversations.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(dynamic conv, bool isDark) {
    final title = conv.otherUser?.displayName ?? (conv.shop?.shopName ?? 'Shop');
    final profilePic = conv.otherUser?.profilePicUrl ?? (conv.shop?.logo ?? '');
    final timeStr = DateFormat('h:mm a').format(conv.lastMessage.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/chat', arguments: {
          'conversationId': conv.conversationId,
          'receiverId': conv.otherUser?.id ?? '',
          'shopId': conv.shop?.id ?? '',
          'title': title,
          'otherUser': conv.otherUser,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            PremiumAvatar(imageUrl: profilePic, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: conv.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





