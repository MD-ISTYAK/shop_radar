import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/community_model.dart';
import '../../services/api_service.dart';

class CommunityState {
  final List<CommunityQuestionModel> questions;
  final bool isLoading;
  final String? error;

  CommunityState({this.questions = const [], this.isLoading = false, this.error});

  CommunityState copyWith({List<CommunityQuestionModel>? questions, bool? isLoading, String? error}) {
    return CommunityState(questions: questions ?? this.questions, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final ApiService _api = ApiService();
  CommunityNotifier() : super(CommunityState());

  Future<void> fetchQuestions({String? tag}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getNearbyQuestions(tag: tag);
      final list = (res.data['data'] as List).map((e) => CommunityQuestionModel.fromJson(e)).toList();
      state = state.copyWith(questions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> postQuestion(String text, {String? area, List<String>? tags}) async {
    try {
      await _api.postQuestion({'text': text, 'area': area ?? '', 'tags': tags ?? []});
      await fetchQuestions();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> answerQuestion(String questionId, String text, {String? shopMentioned}) async {
    try {
      await _api.answerQuestion(questionId, {'text': text, 'shopMentioned': shopMentioned});
      await fetchQuestions();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> upvoteAnswer(String questionId, String answerId) async {
    try {
      await _api.upvoteAnswer(questionId, answerId);
      await fetchQuestions();
    } catch (_) {}
  }
}

final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) => CommunityNotifier());
