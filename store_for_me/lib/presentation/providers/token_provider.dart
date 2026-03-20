import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/token_model.dart';
import '../../services/api_service.dart';

class TokenState {
  final TokenModel? myToken;
  final QueueStatusModel? queueStatus;
  final bool isLoading;
  final String? message;

  const TokenState({this.myToken, this.queueStatus, this.isLoading = false, this.message});

  TokenState copyWith({TokenModel? myToken, QueueStatusModel? queueStatus, bool? isLoading, String? message}) {
    return TokenState(
      myToken: myToken ?? this.myToken,
      queueStatus: queueStatus ?? this.queueStatus,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }
}

class TokenNotifier extends StateNotifier<TokenState> {
  final ApiService _api = ApiService();

  TokenNotifier() : super(const TokenState());

  Future<void> fetchMyToken() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getMyToken();
      if (response.data['success'] == true && response.data['data'] != null) {
        state = state.copyWith(
          myToken: TokenModel.fromJson(response.data['data']),
          isLoading: false,
        );
      } else {
        state = TokenState(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchQueueStatus(String shopId) async {
    try {
      final response = await _api.getQueueStatus(shopId);
      if (response.data['success'] == true) {
        state = state.copyWith(
          queueStatus: QueueStatusModel.fromJson(response.data['data']),
        );
      }
    } catch (e) {
      // ignore
    }
  }

  Future<bool> takeToken(String shopId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.takeQueueToken(shopId);
      if (response.data['success'] == true) {
        state = state.copyWith(
          myToken: TokenModel.fromJson(response.data['data']),
          isLoading: false,
          message: response.data['message'],
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  Future<bool> cancelToken() async {
    if (state.myToken == null) return false;
    try {
      final response = await _api.cancelQueueToken(state.myToken!.id);
      if (response.data['success'] == true) {
        state = TokenState(message: 'Token cancelled');
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> advanceQueue(String shopId) async {
    try {
      final response = await _api.advanceQueue(shopId);
      if (response.data['success'] == true) {
        await fetchQueueStatus(shopId);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}

final tokenProvider = StateNotifierProvider<TokenNotifier, TokenState>((ref) {
  return TokenNotifier();
});
