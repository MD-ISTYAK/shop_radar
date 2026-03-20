import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/models/social_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/shop_management_provider.dart';
import '../widgets/common_widgets.dart';

class ShopManagementScreen extends ConsumerStatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  ConsumerState<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends ConsumerState<ShopManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(shopManagementProvider.notifier).fetchMyContent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopManagementProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Social Content'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts & Reels'),
            Tab(text: 'Stories'),
          ],
        ),
      ),
      body: state.isLoading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabController,
              children: [
                _PostsList(posts: state.myPosts),
                _StoriesList(stories: state.myStories),
              ],
            ),
    );
  }
}

class _PostsList extends ConsumerWidget {
  final List<PostModel> posts;
  const _PostsList({required this.posts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (posts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.post_add,
        title: 'No posts yet',
        subtitle: 'Share your first post with your followers',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(post.isReel ? Icons.videocam : Icons.image, color: AppColors.primary),
                ),
                title: Text(post.isReel ? 'Reel' : 'Post'),
                subtitle: Text(DateFormat.yMMMd().format(post.createdAt)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(context, ref, value, post),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'hide', child: Text(post.isHidden ? 'Unhide' : 'Hide')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              if (post.images.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.images.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: '${AppConstants.uploadsUrl}${post.images[i]}',
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () => _showLikes(context, ref, post),
                    icon: const Icon(Icons.favorite, size: 18),
                    label: Text('${post.likesCount} Likes'),
                  ),
                  TextButton.icon(
                    onPressed: () => _manageComments(context, ref, post),
                    icon: const Icon(Icons.comment, size: 18),
                    label: Text('${post.commentsCount} Comments'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action, PostModel post) async {
    if (action == 'edit') {
      final newContent = await _showEditDialog(context, post.content);
      if (newContent != null) {
        await ref.read(shopManagementProvider.notifier).updatePost(post.id, newContent);
      }
    } else if (action == 'hide') {
      await ref.read(shopManagementProvider.notifier).toggleHidePost(post.id);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Post?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(shopManagementProvider.notifier).deletePost(post.id);
      }
    }
  }

  Future<String?> _showEditDialog(BuildContext context, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter new content'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showLikes(BuildContext context, WidgetRef ref, PostModel post) async {
    final likes = await ref.read(shopManagementProvider.notifier).fetchPostLikes(post.id);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Likes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: likes.isEmpty
                  ? const Center(child: Text('No likes yet'))
                  : ListView.builder(
                      itemCount: likes.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(likes[i].name),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _manageComments(BuildContext context, WidgetRef ref, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Manage Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: post.comments.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : ListView.builder(
                      itemCount: post.comments.length,
                      itemBuilder: (context, i) {
                        final comment = post.comments[i];
                        return ListTile(
                          title: Text(comment.userName),
                          subtitle: Text(comment.text),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(comment.isHidden ? Icons.visibility_off : Icons.visibility, size: 20),
                                onPressed: () => ref.read(shopManagementProvider.notifier).toggleHideComment(post.id, comment.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => ref.read(shopManagementProvider.notifier).deleteComment(post.id, comment.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoriesList extends ConsumerWidget {
  final List<StoryModel> stories;
  const _StoriesList({required this.stories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stories.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.add_to_photos,
        title: 'No stories',
        subtitle: 'Add a story to engage with your customers',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: '${AppConstants.uploadsUrl}${story.imageUrl}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(story.caption.isEmpty ? 'Story' : story.caption),
            subtitle: Text('Expires: ${DateFormat.jm().format(story.expiresAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(story.isHidden ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => ref.read(shopManagementProvider.notifier).toggleHideStory(story.id),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStory(context, ref, story.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteStory(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(shopManagementProvider.notifier).deleteStory(id);
    }
  }
}
