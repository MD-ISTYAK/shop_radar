import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sharing_provider.dart';

class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  final File fileToSend;
  const DeviceDiscoveryScreen({super.key, required this.fileToSend});

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends ConsumerState<DeviceDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sharingProvider.notifier).startDiscovery();
    });
  }

  @override
  void dispose() {
    ref.read(sharingProvider.notifier).stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Device'),
      ),
      body: Column(
        children: [
          _buildDiscoveryHeader(),
          Expanded(
            child: state.discoveredDevices.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.discoveredDevices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final device = state.discoveredDevices[index];
                      return _buildDeviceTile(context, device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary.withAlpha(10),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Searching for nearby devices...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Sharing: ${widget.fileToSend.path.split(Platform.pathSeparator).last}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_tethering, size: 64, color: AppColors.textLight.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('Scanning for devices...'),
          const SizedBox(height: 8),
          Text(
            'Ensure the receiver has clicked "Receive"',
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context, device) {
    return InkWell(
      onTap: () {
        ref.read(sharingProvider.notifier).sendFileToDevice(device, widget.fileToSend);
        Navigator.pushReplacementNamed(context, '/sharing/transfer');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.computer, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(device.ip, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
