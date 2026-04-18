import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/badge_model.dart';
import '../../services/api_service.dart';

class GamificationState {
  final List<BadgeModel> badges;
  final ReferralModel? referral;
  final List<dynamic> leaderboard;
  final bool isLoading;

  GamificationState({this.badges = const [], this.referral, this.leaderboard = const [], this.isLoading = false});

  int get earnedCount => badges.where((b) => b.earned).length;

  GamificationState copyWith({List<BadgeModel>? badges, ReferralModel? referral, List<dynamic>? leaderboard, bool? isLoading}) {
    return GamificationState(
      badges: badges ?? this.badges,
      referral: referral ?? this.referral,
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  final ApiService _api = ApiService();
  GamificationNotifier() : super(GamificationState());

  Future<void> fetchBadges() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getMyBadges();
      final list = (res.data['data'] as List).map((e) => BadgeModel.fromJson(e)).toList();
      state = state.copyWith(badges: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchReferrals() async {
    try {
      final res = await _api.getMyReferrals();
      final referral = ReferralModel.fromJson(res.data['data']);
      state = state.copyWith(referral: referral);
    } catch (_) {}
  }

  Future<bool> applyReferralCode(String code) async {
    try {
      await _api.applyReferralCode(code);
      await fetchReferrals();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchLeaderboard() async {
    try {
      final res = await _api.getLeaderboard();
      state = state.copyWith(leaderboard: res.data['data'] ?? []);
    } catch (_) {}
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) => GamificationNotifier());
