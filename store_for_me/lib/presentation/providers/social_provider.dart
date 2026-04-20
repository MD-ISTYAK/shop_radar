import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/social_models.dart';
import '../../services/api_service.dart';

class SocialState {
  final List<PostModel> feed;
  final List<PostModel> explore;
  final List<StoryGroupModel> stories;
  final List<ReelModel> reels;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreFeed;
  final String? feedCursor;
  final String? error;
  final UserProfileModel? viewingProfile;
  final List<PostModel> profilePosts;

  const SocialState({
    this.feed = const [],
    this.explore = const [],
    this.stories = const [],
    this.reels = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreFeed = true,
    this.feedCursor,
    this.error,
    this.viewingProfile,
    this.profilePosts = const [],
  });

  SocialState copyWith({
    List<PostModel>? feed,
    List<PostModel>? explore,
    List<StoryGroupModel>? stories,
    List<ReelModel>? reels,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreFeed,
    String? feedCursor,
    String? error,
    UserProfileModel? viewingProfile,
    List<PostModel>? profilePosts,
  }) {
    return SocialState(
      feed: feed ?? this.feed,
      explore: explore ?? this.explore,
      stories: stories ?? this.stories,
      reels: reels ?? this.reels,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreFeed: hasMoreFeed ?? this.hasMoreFeed,
      feedCursor: feedCursor ?? this.feedCursor,
      error: error,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      profilePosts: profilePosts ?? this.profilePosts,
    );
  }
}

class SocialNotifier extends StateNotifier<SocialState> {
  final ApiService _api = ApiService();

  SocialNotifier() : super(const SocialState());

  // ===================== FEED =====================
  Future<void> fetchFeed({bool refresh = true}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, feedCursor: null, hasMoreFeed: true);
    } else {
      if (!state.hasMoreFeed || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await _api.getFeedCursor(
        cursor: refresh ? null : state.feedCursor,
        limit: 10,
      );
      if (response.data['success'] == true) {
        final posts = (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
        final nextCursor = response.data['nextCursor'] as String?;
        final hasMore = posts.length >= 10 && nextCursor != null;

        state = state.copyWith(
          feed: refresh ? posts : [...state.feed, ...posts],
          isLoading: false,
          isLoadingMore: false,
          feedCursor: nextCursor ?? (posts.isNotEmpty ? posts.last.id : null),
          hasMoreFeed: hasMore,
        );
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } catch (e) {
      // Fallback to old pagination
      try {
        final response = await _api.getFeed();
        if (response.data['success'] == true) {
          final posts = (response.data['data'] as List)
              .map((e) => PostModel.fromJson(e))
              .toList();
          state = state.copyWith(
            feed: posts,
            isLoading: false,
            isLoadingMore: false,
            hasMoreFeed: false,
          );
        }
      } catch (_) {
        state = state.copyWith(isLoading: false, isLoadingMore: false, error: 'Failed to load feed');
      }
    }
  }

  Future<void> loadMoreFeed() async {
    await fetchFeed(refresh: false);
  }

  // ===================== EXPLORE =====================
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

  // ===================== STORIES =====================
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

  Future<void> markStoryViewed(String storyId) async {
    try {
      await _api.markStoryViewed(storyId);
    } catch (e) {
      // ignore
    }
  }

  // ===================== REELS =====================
  Future<void> fetchReels() async {
    try {
      final response = await _api.getReels();
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final reels = data.map((e) => ReelModel.fromJson(e)).toList();
        state = state.copyWith(reels: reels);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> toggleReelLike(String reelId) async {
    // Optimistic update
    final reels = state.reels.map((r) {
      if (r.id == reelId) {
        return r.copyWith(
          isLikedByMe: !r.isLikedByMe,
          likesCount: r.isLikedByMe ? r.likesCount - 1 : r.likesCount + 1,
        );
      }
      return r;
    }).toList();
    state = state.copyWith(reels: reels);

    try {
      await _api.likeReel(reelId);
    } catch (e) {
      // Revert on failure
      await fetchReels();
    }
  }

  // ===================== POST INTERACTIONS =====================
  Future<bool> toggleLike(String postId) async {
    // Optimistic update on feed
    final updatedFeed = state.feed.map((p) {
      if (p.id == postId) {
        return p.copyWith(
          isLikedByMe: !p.isLikedByMe,
          likesCount: p.isLikedByMe ? p.likeCount - 1 : p.likeCount + 1,
        );
      }
      return p;
    }).toList();

    // Also update explore
    final updatedExplore = state.explore.map((p) {
      if (p.id == postId) {
        return p.copyWith(
          isLikedByMe: !p.isLikedByMe,
          likesCount: p.isLikedByMe ? p.likeCount - 1 : p.likeCount + 1,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(feed: updatedFeed, explore: updatedExplore);

    try {
      final response = await _api.toggleLike(postId);
      return response.data['success'] == true;
    } catch (e) {
      // Revert on error
      await fetchFeed();
      return false;
    }
  }

  Future<bool> addComment(String postId, String text) async {
    try {
      final response = await _api.addComment(postId, text);
      if (response.data['success'] == true) {
        // Optimistic: increment comment count locally
        final updatedFeed = state.feed.map((p) {
          if (p.id == postId) {
            return p.copyWith(commentsCount: p.commentCount + 1);
          }
          return p;
        }).toList();
        state = state.copyWith(feed: updatedFeed);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> toggleSavePost(String postId) async {
    // Optimistic
    final updatedFeed = state.feed.map((p) {
      if (p.id == postId) {
        return p.copyWith(isSavedByMe: !p.isSavedByMe);
      }
      return p;
    }).toList();
    state = state.copyWith(feed: updatedFeed);

    try {
      final post = state.feed.firstWhere((p) => p.id == postId, orElse: () => state.feed.first);
      if (post.isSavedByMe) {
        await _api.unsavePost(postId);
      } else {
        await _api.savePost(postId);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===================== POST CREATION =====================
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

  // ===================== FOLLOW =====================
  Future<bool> toggleFollow(String userId) async {
    try {
      final response = await _api.toggleFollow(userId);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ===================== PROFILE =====================
  Future<void> fetchUserProfile(String userId) async {
    try {
      final response = await _api.getUserProfile(userId);
      if (response.data['success'] == true) {
        final profile = UserProfileModel.fromJson(response.data['data']);
        state = state.copyWith(viewingProfile: profile);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchUserPosts(String userId) async {
    try {
      final response = await _api.getUserPosts(userId);
      if (response.data['success'] == true) {
        final posts = (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
        state = state.copyWith(profilePosts: posts);
      }
    } catch (e) {
      // ignore
    }
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  return SocialNotifier();
});
