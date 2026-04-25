import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sharing_provider.dart';
import '../../data/models/sharing_models.dart';
import '../../../../presentation/providers/auth_provider.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    
    // Base permissions for all Android versions
    List<Permission> permissions = [];
    
    if (Platform.isAndroid) {
      // Check Android version (simplified check for SDK 33)
      // Note: In a real app, you'd use device_info_plus, but we can infer from Permission behavior
      
      // Request storage/media permissions
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied || storageStatus.isLimited) {
        // On Android 13+, Permission.storage might not be the right one
        permissions.add(Permission.storage);
        // Add media permissions for Android 13+
        permissions.add(Permission.photos);
        permissions.add(Permission.videos);
        permissions.add(Permission.audio);
      }

      // Location/Nearby for WiFi Discovery
      permissions.add(Permission.location);
      permissions.add(Permission.nearbyWifiDevices);
    }

    if (permissions.isNotEmpty) {
      statuses = await permissions.request();
    }

    bool allGranted = true;
    
    // On Android 13+, Permission.storage will be denied, but media permissions might be granted
    // We check if at least some critical ones are granted
    if (Platform.isAndroid) {
      final locGranted = statuses[Permission.location]?.isGranted ?? await Permission.location.isGranted;
      final nearbyGranted = statuses[Permission.nearbyWifiDevices]?.isGranted ?? await Permission.nearbyWifiDevices.isGranted;
      
      // Storage logic: either storage is granted (old Android) or media ones are granted (new Android)
      final storageGranted = statuses[Permission.storage]?.isGranted ?? await Permission.storage.isGranted;
      final mediaGranted = (statuses[Permission.photos]?.isGranted ?? await Permission.photos.isGranted) ||
                          (statuses[Permission.videos]?.isGranted ?? await Permission.videos.isGranted);
      
      allGranted = (locGranted || nearbyGranted) && (storageGranted || mediaGranted);
    }

    if (allGranted) {
      setState(() => _permissionsGranted = true);
      _initReceive();
    } else {
      // Check if any critical one is permanently denied
      bool permanentlyDenied = false;
      for (var s in statuses.values) {
        if (s.isPermanentlyDenied) permanentlyDenied = true;
      }
      
      if (permanentlyDenied) {
        _showPermissionDeniedDialog();
      } else {
        // Optional: show a snackbar if partially denied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Some permissions were denied. Discovery or saving might fail.')),
          );
        }
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text('To receive and save files, please grant storage permission in app settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _initReceive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final myName = authState.user?.name ?? 'Shop Radar User';
      ref.read(sharingProvider.notifier).startReceiveMode(myName);
    });
  }

  @override
  void dispose() {
    // We don't stop receive mode on dispose because the user might want to continue receiving in background
    // until they explicitly stop it or the transfer finishes.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharingProvider);
    final transfers = state.activeTransfers.values
        .where((t) => t.type == TransferType.download)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receive Files', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (transfers.isNotEmpty && !_allCompleted(transfers)) {
              _showExitDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (state.isReceiving)
            TextButton(
              onPressed: () => ref.read(sharingProvider.notifier).stopReceiveMode(),
              child: const Text('Stop', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBanner(state, transfers),
          Expanded(
            child: transfers.isEmpty
                ? _buildEmptyState(state)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transfers.length,
                    itemBuilder: (context, index) {
                      return _buildTransferCard(transfers[index]);
                    },
                  ),
          ),
          if (transfers.isNotEmpty && _allCompleted(transfers))
            _buildActionFooter(),
        ],
      ),
    );
  }

  bool _allCompleted(List<TransferProgress> transfers) {
    if (transfers.isEmpty) return false;
    return transfers.every((t) => 
        t.status == TransferStatus.completed || t.status == TransferStatus.failed);
  }

  Widget _buildStatusBanner(SharingState state, List<TransferProgress> transfers) {
    if (!state.isReceiving) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: AppColors.error.withAlpha(20),
        child: const Text(
          'Receive mode is OFF',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (transfers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: AppColors.success.withAlpha(20),
        child: const Text(
          'Ready to receive. Waiting for sender...',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
        ),
      );
    }

    final first = transfers.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withAlpha(10),
      child: Row(
        children: [
          const Icon(Icons.download_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receiving from ${first.peerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${transfers.length} files total',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!_allCompleted(transfers))
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SharingState state) {
    if (!_permissionsGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_rounded, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            const Text(
              'Permission Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Storage permission is needed to save incoming files to your device.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_tethering_rounded, size: 80, color: AppColors.divider),
          const SizedBox(height: 24),
          const Text(
            'Your device is visible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Ask the sender to select your device and send files.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          if (!state.isReceiving)
            ElevatedButton(
              onPressed: _initReceive,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Restart Receive Mode'),
            ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(TransferProgress transfer) {
    final isDone = transfer.status == TransferStatus.completed;
    final isFailed = transfer.status == TransferStatus.failed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDone ? AppColors.success.withAlpha(100) : AppColors.divider.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _getStatusIcon(transfer.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(transfer.bytesSent / (1024 * 1024)).toStringAsFixed(1)} / ${(transfer.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!isDone && !isFailed)
                  Text(
                    '${(transfer.speed / 1024).toStringAsFixed(1)} MB/s',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: transfer.progress,
                minHeight: 6,
                backgroundColor: AppColors.divider.withAlpha(100),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppColors.success : (isFailed ? AppColors.error : AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return const Icon(Icons.check_circle, color: AppColors.success, size: 24);
      case TransferStatus.failed:
        return const Icon(Icons.error, color: AppColors.error, size: 24);
      case TransferStatus.receiving:
      case TransferStatus.sending:
        return const Icon(Icons.downloading, color: AppColors.primary, size: 24);
      default:
        return const Icon(Icons.schedule, color: AppColors.divider, size: 24);
    }
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ref.read(sharingProvider.notifier).resetTransfer();
                Navigator.pop(context);
              },
              child: const Text('Back to Home'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ref.read(sharingProvider.notifier).resetTransfer();
                Navigator.pushReplacementNamed(context, '/magico/files');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('View Files'),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Receiving?'),
        content: const Text('An active transfer is in progress. Leaving this screen might interrupt it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Stop & Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
