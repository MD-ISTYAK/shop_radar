import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/deal_model.dart';
import '../../services/api_service.dart';

class DealState {
  final List<DealModel> deals;
  final List<DealModel> trendingDeals;
  final List<DealModel> savedDeals;
  final bool isLoading;
  final String? error;

  DealState({this.deals = const [], this.trendingDeals = const [], this.savedDeals = const [], this.isLoading = false, this.error});

  DealState copyWith({List<DealModel>? deals, List<DealModel>? trendingDeals, List<DealModel>? savedDeals, bool? isLoading, String? error}) {
    return DealState(
      deals: deals ?? this.deals,
      trendingDeals: trendingDeals ?? this.trendingDeals,
      savedDeals: savedDeals ?? this.savedDeals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DealNotifier extends StateNotifier<DealState> {
  final ApiService _api = ApiService();

  DealNotifier() : super(DealState());

  Future<void> fetchNearbyDeals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getNearbyDeals();
      final list = (res.data['data'] as List).map((e) => DealModel.fromJson(e)).toList();
      state = state.copyWith(deals: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTrendingDeals() async {
    try {
      final res = await _api.getTrendingDeals();
      final list = (res.data['data'] as List).map((e) => DealModel.fromJson(e)).toList();
      state = state.copyWith(trendingDeals: list);
    } catch (_) {}
  }

  Future<void> fetchSavedDeals() async {
    try {
      final res = await _api.getMySavedDeals();
      final list = (res.data['data'] as List).map((e) => DealModel.fromJson(e)).toList();
      state = state.copyWith(savedDeals: list);
    } catch (_) {}
  }

  Future<void> toggleSaveDeal(String dealId) async {
    try {
      await _api.toggleSaveDeal(dealId);
      await fetchNearbyDeals();
      await fetchSavedDeals();
    } catch (_) {}
  }
}

final dealProvider = StateNotifierProvider<DealNotifier, DealState>((ref) => DealNotifier());
