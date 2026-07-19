import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/social_models.dart';
import '../providers/social_provider.dart';
import '../../services/api_service.dart';

class CommentSheet extends ConsumerStatefulWidget {
  final String postId;
  final List<CommentModel> initialComments;

  const CommentSheet({
    super.key,
    required this.postId,
    this.initialComments = const [],
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  bool _isLoading = false;
  CommentModel? _replyingTo;
  late List<CommentModel> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments);
    if (_comments.isEmpty) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final res = await api.getPostComments(widget.postId);
      if (res.data['success'] == true) {
        final data = res.data['data'] as List;
        setState(() {
          _comments = data.map((e) => CommentModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final success = await ref.read(socialProvider.notifier).addComment(
      widget.postId, 
      text,
      parentCommentId: _replyingTo?.id,
    );

    if (success && mounted) {
      _controller.clear();
      // Add optimistic comment
      setState(() {
        _comments.insert(0, CommentModel(
          id: DateTime.now().toString(),
          userId: '',
          userName: 'You',
          text: text,
          parentCommentId: _replyingTo?.id,
          createdAt: DateTime.now(),
        ));
        _replyingTo = null;
      });
    }
    if (mounted) setState(() => _isSending = false);
  }

  void _setReplyingTo(CommentModel comment) {
    setState(() => _replyingTo = comment);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const Divider(height: 1),
          // Comment list
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(height: 12),
                        Text(
                          'No comments yet',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start the conversation.',
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final isReply = comment.parentCommentId != null;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16, left: isReply ? 32 : 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).dividerColor.withAlpha(50),
                              backgroundImage: comment.userProfilePic.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      AppConstants.getImageUrl(comment.userProfilePic))
                                  : null,
                              child: comment.userProfilePic.isEmpty
                                  ? Text(
                                      comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      children: [
                                        TextSpan(
                                          text: comment.userName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        const TextSpan(text: '  '),
                                        TextSpan(
                                          text: comment.text,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        comment.timeAgo,
                                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => _setReplyingTo(comment),
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 11, fontWeight: FontWeight.w600),
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
                    },
                  ),
          ),
          // Input
          Divider(height: 1),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Text(
                    'Replying to @${_replyingTo!.userName}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _isSending
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                          onPressed: _sendComment,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}







