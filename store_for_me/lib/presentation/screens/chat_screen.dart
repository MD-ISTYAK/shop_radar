import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/file_manager.dart';
import '../../services/api_service.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../widgets/premium_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String receiverId;
  final String? shopId;
  final String title;
  final ChatUserModel? otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    this.shopId,
    required this.title,
    this.otherUser,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).fetchMessages(widget.conversationId);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _selectedMedia = File(image.path));
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final magicoPath = await FileManager.getMagicoPath();
      final savePath = p.join(magicoPath, fileName);
      if (await File(savePath).exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File already exists in Magico folder')),
          );
        }
        return;
      }
      await ApiService().downloadFile(url, savePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Magico folder: $fileName'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/magico/files'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedMedia == null) || _isSending) return;

    setState(() => _isSending = true);
    final originalMedia = _selectedMedia;
    _messageController.clear();
    setState(() => _selectedMedia = null);

    try {
      await ref.read(chatProvider.notifier).sendMessage(
        widget.receiverId,
        widget.shopId,
        text,
        mediaFile: originalMedia,
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!chatState.isLoading) _scrollToBottom();
    });

    final conv = chatState.conversations.firstWhere(
      (c) => c.conversationId == widget.conversationId,
      orElse: () => ConversationModel(
        conversationId: widget.conversationId,
        lastMessage: LastMessageModel(createdAt: DateTime.now()),
        otherUser: widget.otherUser,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            PremiumAvatar(imageUrl: conv.otherUser?.profilePicUrl, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.otherUser?.displayName ?? widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    conv.otherUser?.isOnline == true ? 'Online' : 'Offline',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: conv.otherUser?.isOnline == true ? AppColors.success : AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(chatState, currentUserId, isDark),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageList(dynamic chatState, String currentUserId, bool isDark) {
    if (chatState.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final msg = chatState.messages[index];
        final isMine = msg.senderId == currentUserId;
        return _buildMessageBubble(msg, isMine, isDark).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMine, bool isDark) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isMine
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMine ? null : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.mediaUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: msg.mediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(height: 200, color: Colors.grey[200]),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _downloadFile(msg.mediaUrl, 'Media_${msg.id}.jpg'),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (msg.text.isNotEmpty)
                  Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMine ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(msg.createdAt),
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'seen' ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: msg.status == 'seen' ? AppColors.primary : AppColors.textLight,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: AppColors.textLight.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedMedia != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_selectedMedia!, height: 100, width: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMedia = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                onPressed: _pickImage,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}







