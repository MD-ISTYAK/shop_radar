import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/socket_service.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';
import '../../services/notification_service.dart';
import '../providers/locale_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    OrdersScreen(),
    SocialScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Connect to Socket.io
    SocketService().connect().then((_) {
      // Listen for socket notifications globally
      SocketService().onNotification((data) {
        final title = data['title'] ?? 'New Notification';
        final body = data['body'] ?? '';
        final useCustomSound = data['useCustomSound'] == true;
        
        NotificationService().showNotification(
          title: title,
          body: body,
          useCustomSound: useCustomSound,
        );
      });
    });
  }

  @override
  void dispose() {
    SocketService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeNotifier = ref.watch(localeProvider.notifier);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 20),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, localeNotifier.translate('home')),
                _buildNavItem(1, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, localeNotifier.translate('my_orders')),
                _buildNavItem(2, Icons.people_outline_rounded, Icons.people_rounded, localeNotifier.translate('social')),
                _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, localeNotifier.translate('profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 18 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}




