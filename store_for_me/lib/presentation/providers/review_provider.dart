import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/review_model.dart';
import '../../services/api_service.dart';

class ReviewState {
  final List<ReviewModel> reviews;
  final bool isLoading;
  final String? error;

  ReviewState({this.reviews = const [], this.isLoading = false, this.error});

  ReviewState copyWith({List<ReviewModel>? reviews, bool? isLoading, String? error}) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final ApiService _api = ApiService();

  ReviewNotifier() : super(ReviewState());

  Future<void> fetchShopReviews(String shopId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getShopReviews(shopId);
      final list = (res.data['data'] as List).map((e) => ReviewModel.fromJson(e)).toList();
      state = state.copyWith(reviews: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createReview(String shopId, int rating, String text) async {
    try {
      await _api.createReview({'shopId': shopId, 'rating': rating, 'text': text});
      await fetchShopReviews(shopId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleUpvote(String reviewId, String shopId) async {
    try {
      await _api.upvoteReview(reviewId);
      await fetchShopReviews(shopId);
    } catch (_) {}
  }
}

final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) => ReviewNotifier());
