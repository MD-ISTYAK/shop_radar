import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../services/api_service.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _api = ApiService();

  NotificationNotifier() : super(const NotificationState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getNotifications();
      if (response.data['success'] == true) {
        final notifications = (response.data['data'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
        state = state.copyWith(
          notifications: notifications,
          unreadCount: response.data['unreadCount'] ?? 0,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      await fetchNotifications();
    } catch (e) {
      // ignore
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.markAllNotificationsRead();
      await fetchNotifications();
    } catch (e) {
      // ignore
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
