import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sharing_provider.dart';
import '../../../../presentation/providers/auth_provider.dart';

class SharingHomeScreen extends ConsumerWidget {
  const SharingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharingState = ref.watch(sharingProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sharing'),
        actions: [
          if (sharingState.isReceiving)
            IconButton(
              icon: const Text('Stop', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onPressed: () => ref.read(sharingProvider.notifier).stopReceiveMode(),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMainIcon(),
              const SizedBox(height: 32),
              Text(
                'Share Files Offline',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Fast and secure peer-to-peer sharing over local network',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              _buildActionButton(
                context,
                title: 'Send Files',
                subtitle: 'Discovery nearby devices and send',
                icon: Icons.send_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.pushNamed(context, '/sharing/discovery');
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                title: sharingState.isReceiving ? 'Receiving...' : 'Receive Files',
                subtitle: sharingState.isReceiving 
                    ? 'Available for discovery as "Shop Radar User"' 
                    : 'Make your device visible to others',
                icon: Icons.download_rounded,
                color: sharingState.isReceiving ? AppColors.success : AppColors.secondary,
                onTap: () {
                  if (!sharingState.isReceiving) {
                    final authState = ref.read(authProvider);
                    final myName = authState.user?.name ?? 'Shop Radar User';
                    ref.read(sharingProvider.notifier).startReceiveMode(myName);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                title: 'My Received Files',
                subtitle: 'View and manage files in Magico folder',
                icon: Icons.folder_shared_rounded,
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/magico/files'),
              ),
              if (sharingState.activeTransfers.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildTransferStatus(context, ref),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.share_rounded,
        size: 80,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferStatus(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/sharing/transfer'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(30)),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Active File Transfer in Progress')),
            const Icon(Icons.open_in_new, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
