import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/check_in_model.dart';
import '../../services/api_service.dart';

class CheckInState {
  final List<CheckInModel> myCheckIns;
  final bool isLoading;
  final String? error;

  CheckInState({this.myCheckIns = const [], this.isLoading = false, this.error});

  CheckInState copyWith({List<CheckInModel>? myCheckIns, bool? isLoading, String? error}) {
    return CheckInState(myCheckIns: myCheckIns ?? this.myCheckIns, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class CheckInNotifier extends StateNotifier<CheckInState> {
  final ApiService _api = ApiService();
  CheckInNotifier() : super(CheckInState());

  Future<void> fetchMyCheckIns() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getMyCheckIns();
      final list = (res.data['data'] as List).map((e) => CheckInModel.fromJson(e)).toList();
      state = state.copyWith(myCheckIns: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> checkIn(String shopId, {int? microRating, double? lat, double? lng}) async {
    try {
      await _api.checkIn({
        'shopId': shopId,
        'microRating': microRating,
        'lat': lat,
        'lng': lng,
      });
      await fetchMyCheckIns();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final checkInProvider = StateNotifierProvider<CheckInNotifier, CheckInState>((ref) => CheckInNotifier());



