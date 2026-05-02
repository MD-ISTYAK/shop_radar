import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../core/utils/time_utils.dart';

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
    final originalText = _messageController.text;
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
        // Restore text on failure
        _messageController.text = originalText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString().replaceAll('Exception: ', '')}'),
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

    // Schedule scroll after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!chatState.isLoading) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Builder(
              builder: (context) {
                final conv = chatState.conversations.firstWhere(
                  (c) => c.conversationId == widget.conversationId,
                  orElse: () => ConversationModel(
                    conversationId: widget.conversationId, 
                    lastMessage: LastMessageModel(createdAt: DateTime.now()),
                    otherUser: widget.otherUser,
                  ),
                );
                final imageUrl = conv.otherUser?.profilePicUrl ?? '';
                
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight.withAlpha(30),
                  backgroundImage: imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
                  child: imageUrl.isEmpty ? const Icon(Icons.person, size: 20, color: AppColors.primary) : null,
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final conv = chatState.conversations.firstWhere(
                        (c) => c.conversationId == widget.conversationId,
                        orElse: () => ConversationModel(
                          conversationId: widget.conversationId, 
                          lastMessage: LastMessageModel(createdAt: DateTime.now()),
                          otherUser: widget.otherUser,
                        ),
                      );
                      final displayTitle = conv.otherUser?.displayName ?? widget.title;
                      return Text(displayTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final conv = chatState.conversations.firstWhere(
                        (c) => c.conversationId == widget.conversationId,
                        orElse: () => ConversationModel(
                          conversationId: widget.conversationId, 
                          lastMessage: LastMessageModel(createdAt: DateTime.now()),
                          otherUser: widget.otherUser,
                        ),
                      );
                      final otherUser = conv.otherUser;
                      if (otherUser == null) return const SizedBox.shrink();
                      
                      return Text(
                        otherUser.isOnline ? 'Online' : (otherUser.lastSeen != null ? 'Last seen ${TimeUtils.formatIST(otherUser.lastSeen!, pattern: 'h:mm a')}' : 'Offline'),
                        style: TextStyle(
                          fontSize: 11,
                          color: otherUser.isOnline ? Colors.green : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => ref.read(chatProvider.notifier).fetchMessages(widget.conversationId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatState.isLoading
                ? Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No messages yet', 
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color, 
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Send a message to start the conversation', 
                               style: TextStyle(color: Colors.grey, fontSize: 14)
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatState.messages[index];
                          final isMine = msg.senderId == currentUserId;

                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isMine ? AppColors.primary : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMine ? 20 : 4),
                                  bottomRight: Radius.circular(isMine ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isMine ? 10 : 5),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (msg.mediaUrl.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: CachedNetworkImage(
                                              imageUrl: msg.mediaUrl,
                                              placeholder: (context, url) => Container(
                                                height: 200,
                                                width: double.infinity,
                                                color: Theme.of(context).dividerColor.withAlpha(30),
                                                child: Center(child: CircularProgressIndicator()),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(Icons.error),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => _downloadFile(msg.mediaUrl, 'Magico_${msg.id}${p.extension(msg.mediaUrl).isEmpty ? ".jpg" : p.extension(msg.mediaUrl)}'),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black45,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        if (msg.text.isNotEmpty)
                                          Text(
                                            msg.text,
                                            style: TextStyle(
                                              color: isMine ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                              fontSize: 15,
                                              height: 1.3,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              TimeUtils.formatIST(msg.createdAt, pattern: 'h:mm a'),
                                              style: TextStyle(
                                                fontSize: 10,
                                                  color: isMine ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                                              ),
                                            ),
                                            if (isMine) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                msg.status == 'seen' ? Icons.done_all : (msg.status == 'delivered' ? Icons.done_all : Icons.done),
                                                size: 14,
                                                color: msg.status == 'seen' ? Colors.blue.shade300 : Colors.white70,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedMedia != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedMedia!,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMedia = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Theme.of(context).dividerColor.withAlpha(100)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(14.0),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






