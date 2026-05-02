import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/data_saver_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account section
          const _SectionTitle(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: user?.name ?? '',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: AppConstants.supportedLanguages[user?.language ?? 'en'] ?? 'English',
            onTap: () => _showLanguageSheet(context, ref),
          ),
          _SettingsTile(
            icon: Icons.interests,
            title: 'Interests',
            subtitle: user?.interests.isNotEmpty == true ? user!.interests.join(', ') : 'Set your interests',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          // Preferences
          const _SectionTitle(title: 'Preferences'),
          Consumer(builder: (context, ref, _) {
            final isDataSaver = ref.watch(dataSaverProvider);
            return _SettingsTile(
              icon: Icons.data_usage,
              title: 'Data Saver Mode',
              subtitle: 'Reduces image quality & disables autoplay',
              trailing: Switch(
                value: isDataSaver,
                onChanged: (val) => ref.read(dataSaverProvider.notifier).toggle(),
                activeColor: AppColors.primary,
              ),
            );
          }),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage push notifications',
            trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary),
          ),
          Consumer(builder: (context, ref, _) {
            final themeMode = ref.watch(themeProvider);
            final isDark = themeMode == ThemeMode.dark;
            return _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: isDark ? 'Dark mode is ON' : 'Light mode is ON',
              trailing: Switch(
                value: isDark, 
                onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(val),
                activeColor: AppColors.primary,
              ),
            );
          }),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Location Settings',
            subtitle: 'Manage location permissions',
            onTap: () {},
          ),
          // P2P Sharing - temporarily disabled
          // _SettingsTile(
          //   icon: Icons.share_outlined,
          //   title: 'File Sharing',
          //   subtitle: 'P2P offline file sharing',
          //   onTap: () => Navigator.pushNamed(context, '/sharing'),
          // ),
          const SizedBox(height: 16),

          // Support
          const _SectionTitle(title: 'Support'),
          _SettingsTile(icon: Icons.help_outline, title: 'Help & FAQ', onTap: () {}),
          _SettingsTile(icon: Icons.chat_outlined, title: 'Contact Us', onTap: () {}),
          _SettingsTile(icon: Icons.policy_outlined, title: 'Privacy Policy', onTap: () {}),
          _SettingsTile(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
          const SizedBox(height: 16),

          // About
          const _SectionTitle(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '2.0.0',
          ),
          _SettingsTile(icon: Icons.star_outline, title: 'Rate Us', onTap: () {}),
          const SizedBox(height: 24),

          // Danger zone
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          _SettingsTile(icon: Icons.delete_outline, title: 'Delete Account', subtitle: 'Permanently delete your account and data', isDestructive: true, onTap: () {}),
          SizedBox(height: 16),
          Center(
            child: Text('Made with ❤️ by Shop Radar', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...AppConstants.supportedLanguages.entries.map((e) {
              return ListTile(
                title: Text(e.value),
                trailing: ref.read(authProvider).user?.language == e.key
                    ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            }),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodySmall?.color)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary, size: 22),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? AppColors.error : AppColors.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 12, color: isDestructive ? AppColors.error.withAlpha(150) : AppColors.textLight)) : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, size: 20, color: Theme.of(context).textTheme.bodySmall?.color) : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}






