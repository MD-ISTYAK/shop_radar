import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/models/social_models.dart';
import '../widgets/post_card.dart';

class UserPostsScreen extends ConsumerWidget {
  final List<PostModel> posts;
  final int initialIndex;
  final String title;

  const UserPostsScreen({
    super.key,
    required this.posts,
    this.initialIndex = 0,
    this.title = 'Posts',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final currentUserId = auth.user?.id ?? '';
    final scrollController = ScrollController();

    // Scroll to initial index after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialIndex > 0) {
        // Simple heuristic for height: 500 per post
        scrollController.jumpTo(initialIndex * 500.0);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        controller: scrollController,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostCard(
            post: post,
            currentUserId: currentUserId,
            onLike: () => ref.read(socialProvider.notifier).toggleLike(post.id),
            onSave: () => ref.read(socialProvider.notifier).toggleSavePost(post.id),
            onComment: () => _showComments(context, post),
            onDelete: () async {
              final success = await ref.read(socialProvider.notifier).deletePost(post.id);
              if (success && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
              }
            },
            onEdit: (content) => _showEditDialog(context, ref, post, content),
          );
        },
      ),
    );
  }

  void _showComments(BuildContext context, PostModel post) {
    // Implement comments navigation or sheet if needed
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, PostModel post, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Edit caption...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                Navigator.pop(context);
                await ref.read(socialProvider.notifier).updatePost(post.id, newContent);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
