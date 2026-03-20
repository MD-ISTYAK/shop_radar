import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_post': return Icons.article_outlined;
      case 'offer': return Icons.local_offer_outlined;
      case 'story': return Icons.auto_stories_outlined;
      case 'token_update': return Icons.confirmation_number_outlined;
      case 'shop_open': return Icons.store_outlined;
      case 'follow': return Icons.person_add_outlined;
      case 'like': return Icons.favorite_outline;
      case 'comment': return Icons.chat_bubble_outline;
      case 'delivery': return Icons.delivery_dining_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_post': return AppColors.primary;
      case 'offer': return AppColors.warning;
      case 'like': return AppColors.error;
      case 'follow': return AppColors.info;
      case 'delivery': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Read All'),
            ),
        ],
      ),
      body: state.isLoading
          ? const LoadingIndicator()
          : state.notifications.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.notifications_none,
                  title: 'No notifications',
                  subtitle: 'You\'re all caught up!',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final n = state.notifications[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: n.read ? AppColors.card : AppColors.primaryLight.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: n.read ? null : Border.all(color: AppColors.primary.withAlpha(30)),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(n.type).withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getNotificationIcon(n.type), color: _getNotificationColor(n.type), size: 22),
                          ),
                          title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w600, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n.body.isNotEmpty) Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(DateFormat.yMMMd().add_jm().format(n.createdAt), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          onTap: () {
                            if (!n.read) ref.read(notificationProvider.notifier).markAsRead(n.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
