import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/socket_service.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';
import '../../services/notification_service.dart';
import '../widgets/premium_widgets.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const SizedBox(), // Placeholder for Post (+) button action
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SocketService().connect().then((_) {
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

  void _onTabTapped(int index) {
    if (index == 2) {
      // Show Post Creation Modal or Navigate
      _showPostOptions();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create New',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildPostOption(
              icon: Icons.post_add_rounded,
              title: 'Create Post',
              subtitle: 'Share a photo or video to your feed',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
              },
            ),
            const SizedBox(height: 16),
            _buildPostOption(
              icon: Icons.store_rounded,
              title: 'List Product',
              subtitle: 'Add a new product to your shop',
              onTap: () {
                Navigator.pop(context);
                // Navigate to add product
              },
            ),
            const SizedBox(height: 16),
            _buildPostOption(
              icon: Icons.share_rounded,
              title: 'Share File',
              subtitle: 'Transfer files wirelessly with Magico',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/magico/files');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPostOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: PremiumNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}





