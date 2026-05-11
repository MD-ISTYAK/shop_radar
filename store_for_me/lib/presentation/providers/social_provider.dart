import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:store_for_me/data/models/social_models.dart';
import 'package:store_for_me/services/api_service.dart';

class SocialState {
  final List<PostModel> feed;
  final List<PostModel> explore;
  final List<StoryGroupModel> stories;
  final List<ReelModel> reels;
  final String? targetReelId;
  final bool isLoading;
  final bool isProfileLoading;
  final bool isLoadingMore;
  final bool hasMoreFeed;
  final String? feedCursor;
  final String? error;
  final UserProfileModel? viewingProfile;
  final List<PostModel> profilePosts;
  final List<UserProfileModel> suggestedUsers;
  final String lastLoadedProfileId;

  const SocialState({
    this.feed = const [],
    this.explore = const [],
    this.stories = const [],
    this.reels = const [],
    this.targetReelId,
    this.isLoading = false,
    this.isProfileLoading = false,
    this.isLoadingMore = false,
    this.hasMoreFeed = true,
    this.feedCursor,
    this.error,
    this.viewingProfile,
    this.profilePosts = const [],
    this.suggestedUsers = const [],
    this.lastLoadedProfileId = '',
  });

  SocialState copyWith({
    List<PostModel>? feed,
    List<PostModel>? explore,
    List<StoryGroupModel>? stories,
    List<ReelModel>? reels,
    String? targetReelId,
    bool? isLoading,
    bool? isProfileLoading,
    bool? isLoadingMore,
    bool? hasMoreFeed,
    String? feedCursor,
    String? error,
    UserProfileModel? viewingProfile,
    List<PostModel>? profilePosts,
    List<UserProfileModel>? suggestedUsers,
    String? lastLoadedProfileId,
  }) {
    return SocialState(
      feed: feed ?? this.feed,
      explore: explore ?? this.explore,
      stories: stories ?? this.stories,
      reels: reels ?? this.reels,
      targetReelId: targetReelId ?? this.targetReelId,
      isLoading: isLoading ?? this.isLoading,
      isProfileLoading: isProfileLoading ?? this.isProfileLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreFeed: hasMoreFeed ?? this.hasMoreFeed,
      feedCursor: feedCursor ?? this.feedCursor,
      error: error,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      profilePosts: profilePosts ?? this.profilePosts,
      suggestedUsers: suggestedUsers ?? this.suggestedUsers,
      lastLoadedProfileId: lastLoadedProfileId ?? this.lastLoadedProfileId,
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
      debugPrint('FETCH FEED RESPONSE: ${response.statusCode} - ${response.data}');
      
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        final List<PostModel> posts = data.map((e) => PostModel.fromJson(e)).toList();
        
        state = state.copyWith(
          feed: refresh ? posts : [...state.feed, ...posts],
          isLoading: false,
          isLoadingMore: false,
          hasMoreFeed: posts.length == 10,
          feedCursor: posts.isNotEmpty ? posts.last.createdAt.toIso8601String() : null,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false, error: response.data['message'] ?? 'Failed to load feed');
      }
    } catch (e) {
      debugPrint('FETCH FEED ERROR: $e');
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e.toString());
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
      debugPrint('FETCH STORIES RESPONSE: ${response.data}');
      if (response.data['success'] == true) {
        final groups = (response.data['data'] as List)
            .map((e) => StoryGroupModel.fromJson(e))
            .toList();
        debugPrint('FETCHED ${groups.length} STORY GROUPS');
        state = state.copyWith(stories: groups);
      }
    } catch (e) {
      debugPrint('FETCH STORIES ERROR: $e');
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

      // Log response size
      final resSize = response.toString().length / 1024;
      print('DEBUG: Reels API Response Size: ${resSize.toStringAsFixed(2)} KB');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        final reels = data.map((e) => ReelModel.fromJson(e)).toList();
        state = state.copyWith(reels: reels);
      }
    } catch (e) {
      // ignore
    }
  }

  void setTargetReelId(String? reelId) {
    state = state.copyWith(targetReelId: reelId);
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

  Future<bool> addComment(String postId, String text, {String? parentCommentId}) async {
    try {
      final response = await _api.addComment(postId, text, parentCommentId: parentCommentId);
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
  Future<bool> createPost(FormData data, {void Function(int, int)? onSendProgress}) async {
    try {
      final response = await _api.createPost(data, onSendProgress: onSendProgress);
      debugPrint('CREATE POST RESPONSE: ${response.statusCode} - ${response.data}');
      if (response.data['success'] == true) {
        await fetchFeed();
        await fetchReels();
        return true;
      }
    } catch (e) {
      debugPrint('CREATE POST ERROR: $e');
    }
    return false;
  }

  Future<bool> updatePost(String postId, String content) async {
    // Optimistic update
    final List<PostModel> updatedFeed = state.feed.map((p) {
      if (p.id == postId) {
        return p.copyWith(content: content);
      }
      return p;
    }).toList();

    final List<PostModel> updatedExplore = state.explore.map((p) {
      if (p.id == postId) {
        return p.copyWith(content: content);
      }
      return p;
    }).toList();

    final List<PostModel> updatedProfilePosts = state.profilePosts.map((p) {
      if (p.id == postId) {
        return p.copyWith(content: content);
      }
      return p;
    }).toList();

    state = state.copyWith(
      feed: updatedFeed,
      explore: updatedExplore,
      profilePosts: updatedProfilePosts,
    );

    try {
      final response = await _api.updatePost(postId, content);
      return response.data['success'] == true;
    } catch (e) {
      // Revert if needed or refresh
      await fetchFeed();
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    // Optimistic update
    final List<PostModel> updatedFeed = state.feed.where((p) => p.id != postId).toList();
    final List<PostModel> updatedExplore = state.explore.where((p) => p.id != postId).toList();
    final List<PostModel> updatedProfilePosts = state.profilePosts.where((p) => p.id != postId).toList();

    state = state.copyWith(
      feed: updatedFeed,
      explore: updatedExplore,
      profilePosts: updatedProfilePosts,
    );

    try {
      final response = await _api.deletePost(postId);
      debugPrint('DELETE POST RESPONSE: ${response.data}');
      if (response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DELETE POST ERROR: $e');
      // Revert or refresh
      await fetchFeed();
      return false;
    }
  }

  Future<bool> createStory(FormData data, {void Function(int, int)? onSendProgress}) async {
    try {
      final response = await _api.createStory(data, onSendProgress: onSendProgress);
      debugPrint('CREATE STORY RESPONSE: ${response.data}');
      if (response.data['success'] == true) {
        await fetchStories();
        return true;
      }
    } catch (e) {
      debugPrint('CREATE STORY ERROR: $e');
      // ignore
    }
    return false;
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      final response = await _api.deleteStory(storyId);
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
  Future<bool> toggleFollow(String targetUserId, String currentUserId) async {
    // 1. Identify current follow state for target user
    bool isNowFollowing = false;
    final targetInView = state.viewingProfile?.id == targetUserId;
    if (targetInView) {
      isNowFollowing = !state.viewingProfile!.isFollowing;
    } else {
      final suggestion = state.suggestedUsers.cast<UserProfileModel?>().firstWhere(
        (u) => u?.id == targetUserId, 
        orElse: () => null
      );
      if (suggestion != null) {
        isNowFollowing = !suggestion.isFollowing;
      }
    }

    // 2. Optimistic update for viewing profile (if target)
    final currentProfile = state.viewingProfile;
    if (currentProfile != null && currentProfile.id == targetUserId) {
      final updatedProfile = currentProfile.copyWith(
        isFollowing: isNowFollowing,
        followersCount: isNowFollowing 
            ? currentProfile.followersCount + 1 
            : currentProfile.followersCount - 1,
      );
      state = state.copyWith(viewingProfile: updatedProfile);
    }

    // 3. Optimistic update for MY profile followingCount (if currently viewing ME)
    if (currentProfile != null && currentProfile.id == currentUserId && currentUserId != targetUserId) {
      final updatedProfile = currentProfile.copyWith(
        followingCount: isNowFollowing 
            ? currentProfile.followingCount + 1 
            : currentProfile.followingCount - 1,
      );
      state = state.copyWith(viewingProfile: updatedProfile);
    }

    // 4. Optimistic update for suggested users
    final updatedSuggested = state.suggestedUsers.map((u) {
      if (u.id == targetUserId) {
        return u.copyWith(isFollowing: isNowFollowing);
      }
      return u;
    }).toList();

    state = state.copyWith(suggestedUsers: updatedSuggested);

    try {
      final response = await _api.toggleFollow(targetUserId);
      return response.data['success'] == true;
    } catch (e) {
      // Revert viewing profile on failure
      if (currentProfile != null) {
        state = state.copyWith(viewingProfile: currentProfile);
      }
      return false;
    }
  }

  // ===================== PROFILE =====================
  
  /// Atomic loader for profile data
  Future<void> loadFullProfile(String userId) async {
    if (userId.isEmpty) return;
    
    debugPrint('SocialNotifier: Loading full profile for userId: $userId');
    // 1. Set initial loading state
    state = state.copyWith(
      isProfileLoading: true,
      lastLoadedProfileId: '', 
      error: null, 
      viewingProfile: state.viewingProfile?.id == userId ? state.viewingProfile : null,
      profilePosts: state.viewingProfile?.id == userId ? state.profilePosts : [],
    );

    String? errorMessage;

    try {
      debugPrint('SocialNotifier: Triggering parallel API calls...');
      // 2. Execute all in parallel and WAIT for results
      final results = await Future.wait([
        _fetchUserProfileData(userId).catchError((e) {
          debugPrint('SocialNotifier: Profile fetch error: $e');
          errorMessage = e.toString();
          return null as UserProfileModel?;
        }),
        _fetchUserPostsData(userId),
        _fetchSuggestedUsersData(),
      ]);
      
      final profile = results[0] as UserProfileModel?;
      final posts = results[1] as List<PostModel>?;
      final suggested = results[2] as List<UserProfileModel>?;

      debugPrint('SocialNotifier: Data received. Profile: ${profile?.username}, Posts: ${posts?.length}, Suggested: ${suggested?.length}');

      // 3. Update state ONCE with all results
      state = state.copyWith(
        isProfileLoading: false,
        viewingProfile: profile ?? state.viewingProfile,
        profilePosts: posts ?? state.profilePosts,
        suggestedUsers: suggested ?? state.suggestedUsers,
        lastLoadedProfileId: profile != null ? userId : '', 
        error: profile == null ? (errorMessage ?? state.error ?? 'Profile not found') : null,
      );
      debugPrint('SocialNotifier: State updated. isProfileLoading: false, lastLoadedProfileId: ${state.lastLoadedProfileId}');
    } catch (e) {
      debugPrint('SocialNotifier: CRITICAL Error in loadFullProfile: $e');
      state = state.copyWith(
        isProfileLoading: false, 
        lastLoadedProfileId: '',
        error: e.toString(),
      );
    }
  }

  // Internal helpers that return data instead of updating state directly
  Future<UserProfileModel?> _fetchUserProfileData(String userId) async {
    try {
      final response = await _api.getUserProfile(userId);
      if (response.data['success'] == true) {
        return UserProfileModel.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('Error in _fetchUserProfileData: $e');
      rethrow; // Rethrow so caller can catch error message
    }
    return null;
  }

  Future<List<PostModel>?> _fetchUserPostsData(String userId) async {
    try {
      final response = await _api.getUserPosts(userId);
      if (response.data['success'] == true) {
        final List<dynamic> postsData = response.data['data'];
        return postsData.map((json) => PostModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error in _fetchUserPostsData: $e');
    }
    return null;
  }

  Future<List<UserProfileModel>?> _fetchSuggestedUsersData() async {
    try {
      final response = await _api.getSuggestedUsers();
      if (response.data['success'] == true) {
        final List<dynamic> usersData = response.data['data'];
        return usersData.map((json) => UserProfileModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error in _fetchSuggestedUsersData: $e');
    }
    return null;
  }

  // Preserve public methods for simple refreshes
  Future<void> fetchUserProfile(String userId) async {
    state = state.copyWith(isProfileLoading: true);
    final profile = await _fetchUserProfileData(userId);
    state = state.copyWith(
      viewingProfile: profile,
      isProfileLoading: false,
      lastLoadedProfileId: profile != null ? userId : state.lastLoadedProfileId,
    );
  }

  Future<void> fetchSuggestedUsers() async {
    final suggested = await _fetchSuggestedUsersData();
    if (suggested != null) {
      state = state.copyWith(suggestedUsers: suggested);
    }
  }

  Future<void> fetchUserPosts(String userId) async {
    state = state.copyWith(isProfileLoading: true);
    final posts = await _fetchUserPostsData(userId);
    state = state.copyWith(
      profilePosts: posts ?? [],
      isProfileLoading: false,
    );
  }

  // ===================== REPORT =====================
  Future<bool> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _api.reportContent(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        description: description,
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ===================== SAVED POSTS =====================
  Future<List<PostModel>> fetchSavedPosts({String? cursor, int limit = 20}) async {
    try {
      final response = await _api.getSavedPosts(cursor: cursor, limit: limit);
      if (response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

}

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>((ref) {
  return SocialNotifier();
});
