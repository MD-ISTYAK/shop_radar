import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/social_models.dart';
import '../../data/models/chat_models.dart'; // For user model in likes
import '../../services/api_service.dart';

class ShopManagementState {
  final List<PostModel> myPosts;
  final List<StoryModel> myStories;
  final bool isLoading;
  final String? error;

  const ShopManagementState({
    this.myPosts = const [],
    this.myStories = const [],
    this.isLoading = false,
    this.error,
  });

  ShopManagementState copyWith({
    List<PostModel>? myPosts,
    List<StoryModel>? myStories,
    bool? isLoading,
    String? error,
  }) {
    return ShopManagementState(
      myPosts: myPosts ?? this.myPosts,
      myStories: myStories ?? this.myStories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShopManagementNotifier extends StateNotifier<ShopManagementState> {
  final ApiService _api = ApiService();

  ShopManagementNotifier() : super(const ShopManagementState());

  Future<void> fetchMyContent() async {
    state = state.copyWith(isLoading: true);
    try {
      final postRes = await _api.getMyPosts();
      final storyRes = await _api.getMyStories();

      List<PostModel> posts = [];
      List<StoryModel> stories = [];

      if (postRes.data['success'] == true) {
        posts = (postRes.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
      }

      if (storyRes.data['success'] == true) {
        stories = (storyRes.data['data'] as List)
            .map((e) => StoryModel.fromJson(e))
            .toList();
      }

      state = state.copyWith(myPosts: posts, myStories: stories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load content');
    }
  }

  // Post Actions
  Future<bool> updatePost(String postId, String content) async {
    try {
      final res = await _api.updatePost(postId, content);
      if (res.data['success'] == true) {
        await fetchMyContent();
        return true;
      }
    } catch (e) { /* ignore */ }
    return false;
  }

  Future<bool> deletePost(String postId) async {
    try {
      final res = await _api.deletePost(postId);
      if (res.data['success'] == true) {
        await fetchMyContent();
        return true;
      }
    } catch (e) { /* ignore */ }
    return false;
  }

  Future<bool> toggleHidePost(String postId) async {
    try {
      final res = await _api.toggleHidePost(postId);
      if (res.data['success'] == true) {
        await fetchMyContent();
        return true;
      }
    } catch (e) { /* ignore */ }
    return false;
  }

  // Story Actions
  Future<bool> deleteStory(String storyId) async {
    try {
      final res = await _api.deleteStory(storyId);
      if (res.data['success'] == true) {
        await fetchMyContent();
        return true;
      }
    } catch (e) { /* ignore */ }
    return false;
  }

  Future<bool> toggleHideStory(String storyId) async {
    try {
      final res = await _api.toggleHideStory(storyId);
      if (res.data['success'] == true) {
        await fetchMyContent();
        return true;
      }
    } catch (e) { /* ignore */ }
    return false;
  }

  // Comment Actions
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final res = await _api.deleteComment(postId, commentId);
      if (res.data['success'] == true) {
        await fetchMyContent();
        return true;
      }
    } catch (e) { /* ignore */ }
    return false;
  }

  Future<bool> toggleHideComment(String postId, String commentId) async {
    try {
      final res = await _api.toggleHideComment(postId, commentId);
      if (res.data['success'] == true) {
        await fetchMyContent();
        return true;
      }
    } catch (e) { /* ignore */ }
    return false;
  }

  Future<List<ChatUserModel>> fetchPostLikes(String postId) async {
    try {
      final res = await _api.getPostLikes(postId);
      if (res.data['success'] == true) {
        return (res.data['data'] as List)
            .map((e) => ChatUserModel.fromJson(e))
            .toList();
      }
    } catch (e) { /* ignore */ }
    return [];
  }
}

final shopManagementProvider = StateNotifierProvider<ShopManagementNotifier, ShopManagementState>((ref) {
  return ShopManagementNotifier();
});
