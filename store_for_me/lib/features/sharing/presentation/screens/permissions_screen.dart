import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  Map<String, bool> _permissionStatus = {
    'storage': false,
    'nearby': false,
    'location': false,
    'bluetooth': false,
  };

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    final storage = await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted;
    final nearby = Platform.isAndroid
        ? await Permission.nearbyWifiDevices.isGranted
        : true;
    final location = await Permission.location.isGranted;
    final bluetooth = await Permission.bluetooth.isGranted ||
        await Permission.bluetoothScan.isGranted;

    if (mounted) {
      setState(() {
        _permissionStatus = {
          'storage': storage,
          'nearby': nearby,
          'location': location,
          'bluetooth': bluetooth,
        };
      });
    }

    // If all granted, pop back
    if (storage && (nearby || !Platform.isAndroid) && location && bluetooth) {
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _requestPermission(String key) async {
    Permission permission;
    switch (key) {
      case 'storage':
        permission = Permission.manageExternalStorage;
        break;
      case 'nearby':
        permission = Permission.nearbyWifiDevices;
        break;
      case 'location':
        permission = Permission.location;
        break;
      case 'bluetooth':
        permission = Permission.bluetoothScan;
        break;
      default:
        return;
    }
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _checkAllPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Permission Required',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: isDark
                  ? AppColors.darkSurface
                  : const Color(0xFFF0F9FF),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 56,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions Needed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Due to device limitations, several permissions\nare needed to ensure smooth file transfer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Permissions list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPermissionTile(
                    context,
                    key: 'storage',
                    icon: Icons.folder_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Storage',
                    subtitle:
                        'Required to read and save files on your device.',
                  ),
                  _buildPermissionTile(
                    context,
                    key: 'bluetooth',
                    icon: Icons.bluetooth_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Bluetooth',
                    subtitle:
                        'Connect to other devices directly without a hotspot password.',
                  ),
                  _buildPermissionTile(
                    context,
                    key: 'location',
                    icon: Icons.location_on_rounded,
                    color: const Color(0xFF16A34A),
                    title: 'Location',
                    subtitle:
                        'Required to discover nearby devices on the same network.',
                  ),
                  _buildPermissionTile(
                    context,
                    key: 'nearby',
                    icon: Icons.wifi_tethering_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Nearby Devices (Wi-Fi)',
                    subtitle:
                        'Allows high-speed file sharing via Wi-Fi Direct.',
                  ),
                ],
              ),
            ),

            // Grant All button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () async {
                  await [
                    Permission.manageExternalStorage,
                    Permission.bluetooth,
                    Permission.bluetoothScan,
                    Permission.location,
                    Permission.nearbyWifiDevices,
                  ].request();
                  await _checkAllPermissions();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Grant All Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context, {
    required String key,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final isGranted = _permissionStatus[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withAlpha(80)
              : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isGranted
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _requestPermission(key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
