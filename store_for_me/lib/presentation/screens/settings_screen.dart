import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/data_saver_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentLang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Account Settings
          const _SectionTitle(title: 'Account & Identity'),
          _SectionCard(children: [
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: user?.name.isNotEmpty == true ? user!.name : 'Update personal details',
              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
            ),
            _SettingsTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: AppConstants.supportedLanguages[currentLang] ?? 'English',
              onTap: () => _showLanguageSheet(context, ref),
            ),
            _SettingsTile(
              icon: Icons.interests_outlined,
              title: 'My Business & Product Interests',
              subtitle: user?.interests.isNotEmpty == true
                  ? user!.interests.join(', ')
                  : 'Set preferences for recommendations',
              onTap: () => _showInterestsSheet(context, user),
            ),
          ]),
          const SizedBox(height: 16),

          // 2. Preferences
          const _SectionTitle(title: 'App Preferences'),
          _SectionCard(children: [
            Consumer(builder: (context, ref, _) {
              final themeMode = ref.watch(themeProvider);
              final isDark = themeMode == ThemeMode.dark;
              return _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: isDark ? 'Dark mode enabled' : 'Light mode enabled',
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(val),
                  activeThumbColor: AppColors.primary,
                ),
              );
            }),
            Consumer(builder: (context, ref, _) {
              final isDataSaver = ref.watch(dataSaverProvider);
              return _SettingsTile(
                icon: Icons.data_usage_outlined,
                title: 'Data Saver Mode',
                subtitle: 'Reduces image quality & saves bandwidth',
                trailing: Switch(
                  value: isDataSaver,
                  onChanged: (val) => ref.read(dataSaverProvider.notifier).toggle(),
                  activeThumbColor: AppColors.primary,
                ),
              );
            }),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Manage order updates, offers & alerts',
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            _SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'Location Permissions',
              subtitle: 'Manage GPS location & nearby radar',
              onTap: () => _showLocationSettingsSheet(context),
            ),
          ]),
          const SizedBox(height: 16),

          // 3. Support & Legal
          const _SectionTitle(title: 'Support & Legal'),
          _SectionCard(children: [
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              onTap: () => _showInfoModal(
                context,
                'Help & FAQ',
                'Find answers to common questions about Business Radar orders, local deliveries, business manager tools, and refunds.\n\nSupport Portal: https://businessradar.app/help',
              ),
            ),
            _SettingsTile(
              icon: Icons.chat_outlined,
              title: 'Contact Support',
              onTap: () => _showInfoModal(
                context,
                'Contact Customer Support',
                'Support Email: support@businessradar.app\nToll-Free Helpline: +91 1800-123-7467\n\nOur support team is available 24/7.',
              ),
            ),
            _SettingsTile(
              icon: Icons.policy_outlined,
              title: 'Privacy Policy',
              onTap: () => _showInfoModal(
                context,
                'Privacy Policy',
                'Your privacy is fundamental to Business Radar. We encrypt transactions and safeguard your personal data.\n\nRead full policy: https://businessradar.app/privacy',
              ),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => _showInfoModal(
                context,
                'Terms of Service',
                'Read the terms governing the use of Business Radar services at https://businessradar.app/terms',
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 4. Account Actions
          const _SectionTitle(title: 'Account Security'),
          _SectionCard(children: [
            const _SettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: 'Business Radar v2.5.0 (Build 2026)',
            ),
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out from this device',
              onTap: () => _showLogoutDialog(context, ref),
            ),
            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently erase account & data',
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Business Radar • Solving Issues for All Businesses 📡',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Helper Sheets & Dialogs

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(localeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Select Language (भाषा चुनें)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...AppConstants.supportedLanguages.entries.map((e) {
              final isSelected = currentLang == e.key;
              return ListTile(
                title: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(localeProvider.notifier).setLocale(e.key);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ App language set to ${e.value}'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            }),
          ],
        );
      },
    );
  }

  void _showInterestsSheet(BuildContext context, UserModel? user) {
    final categories = ['Grocery', 'Electronics', 'Clothing', 'AC & Appliance Repair', 'Tea & Coffee Stalls', 'Gyms & Fitness', 'Salons & Beauty'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Business & Shopping Preferences', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = user?.interests.contains(cat) == true;
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {},
                    selectedColor: AppColors.primary.withAlpha(40),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Save Preferences'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Location Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.gps_fixed, color: AppColors.primary),
                title: Text('Precise GPS Access'),
                subtitle: Text('Used to display nearby businesses, carts, repair services, and delivery tracking.'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out from Business Radar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
        content: const Text(
          'WARNING: Permanently deleting your account will erase all active orders, registered businesses, and wallet balance. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion request received. Our support team will process it within 24 hours.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodySmall?.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            children: [
              children[index],
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  endIndent: 12,
                  color: isDark ? Colors.white12 : Colors.grey.withAlpha(30),
                ),
            ],
          );
        }),
      ),
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive
        ? AppColors.error
        : Theme.of(context).textTheme.bodyLarge?.color;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withAlpha(20)
              : AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: isDestructive
                    ? AppColors.error.withAlpha(160)
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).textTheme.bodySmall?.color)
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: false,
    );
  }
}
