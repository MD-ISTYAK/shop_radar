import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final user = await _authService.getUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      // Try to get location
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      final response = await _api.register({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        if (position != null) 'lat': position.latitude,
        if (position != null) 'lng': position.longitude,
      });

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = UserModel.fromJson(response.data['data']['user']);
        await _authService.saveToken(token);
        await _authService.saveUser(user);
        await _api.saveToken(token);
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: response.data['message'] ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, error: message);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _api.login({
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = UserModel.fromJson(response.data['data']['user']);
        await _authService.saveToken(token);
        await _authService.saveUser(user);
        await _api.saveToken(token);
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: response.data['message'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, error: message);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _api.deleteToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      try {
        final dioError = e as dynamic;
        if (dioError.response?.data != null) {
          return dioError.response.data['message'] ?? 'An error occurred';
        }
      } catch (_) {}
    }
    return 'An error occurred. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
