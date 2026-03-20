import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/social_models.dart';
import '../../services/api_service.dart';

class SocialState {
  final List<PostModel> feed;
  final List<PostModel> explore;
  final List<StoryGroupModel> stories;
  final List<PostModel> reels;
  final bool isLoading;
  final String? error;

  const SocialState({
    this.feed = const [],
    this.explore = const [],
    this.stories = const [],
    this.reels = const [],
    this.isLoading = false,
    this.error,
  });

  SocialState copyWith({
    List<PostModel>? feed,
    List<PostModel>? explore,
    List<StoryGroupModel>? stories,
    List<PostModel>? reels,
    bool? isLoading,
    String? error,
  }) {
    return SocialState(
      feed: feed ?? this.feed,
      explore: explore ?? this.explore,
      stories: stories ?? this.stories,
      reels: reels ?? this.reels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SocialNotifier extends StateNotifier<SocialState> {
  final ApiService _api = ApiService();

  SocialNotifier() : super(const SocialState());

  Future<void> fetchFeed() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getFeed();
      if (response.data['success'] == true) {
        final posts = (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
        state = state.copyWith(feed: posts, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load feed');
    }
  }

  Future<void> fetchExplore() async {
    try {
      final response = await _api.explorePosts();
      if (response.data['success'] == true) {
        final posts = (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
        state = state.copyWith(explore: posts);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchStories() async {
    try {
      final response = await _api.getStories();
      if (response.data['success'] == true) {
        final groups = (response.data['data'] as List)
            .map((e) => StoryGroupModel.fromJson(e))
            .toList();
        state = state.copyWith(stories: groups);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchReels() async {
    try {
      final response = await _api.getReels();
      if (response.data['success'] == true) {
        final reels = (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
        state = state.copyWith(reels: reels);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<bool> toggleLike(String postId) async {
    try {
      final response = await _api.toggleLike(postId);
      if (response.data['success'] == true) {
        await fetchFeed();
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> addComment(String postId, String text) async {
    try {
      final response = await _api.addComment(postId, text);
      if (response.data['success'] == true) {
        await fetchFeed();
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> createPost(FormData data) async {
    try {
      final response = await _api.createPost(data);
      if (response.data['success'] == true) {
        await fetchFeed();
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> createStory(FormData data) async {
    try {
      final response = await _api.createStory(data);
      if (response.data['success'] == true) {
        await fetchStories();
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> toggleFollow(String shopId) async {
    try {
      final response = await _api.toggleFollow(shopId);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  return SocialNotifier();
});
