import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sharing_provider.dart';
import '../../data/models/sharing_models.dart';

class FileTransferScreen extends ConsumerWidget {
  const FileTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sharingProvider);
    final transfer = state.currentTransfer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Transfer'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (transfer?.status == TransferStatus.completed || 
                transfer?.status == TransferStatus.failed) {
              ref.read(sharingProvider.notifier).resetTransfer();
              Navigator.pop(context);
            } else {
              _showCancelDialog(context, ref);
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: transfer == null 
              ? const Text('No active transfer')
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(transfer.status),
                    const SizedBox(height: 32),
                    Text(
                      transfer.status == TransferStatus.sending ? 'Sending File' : 'Receiving File',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transfer.fileName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 48),
                    _buildProgressBar(transfer),
                    const SizedBox(height: 16),
                    _buildTransferInfo(transfer),
                    const SizedBox(height: 64),
                    if (transfer.status != TransferStatus.completed && 
                        transfer.status != TransferStatus.failed)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Transfer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: () => _showCancelDialog(context, ref),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          ref.read(sharingProvider.notifier).resetTransfer();
                          Navigator.pop(context);
                        },
                        child: const Text('Dismiss'),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildIcon(TransferStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case TransferStatus.completed:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        break;
      case TransferStatus.failed:
        icon = Icons.error_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.cloud_sync_rounded;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 80, color: color),
    );
  }

  Widget _buildProgressBar(TransferProgress transfer) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: transfer.progress,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
          backgroundColor: AppColors.divider,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(transfer.progress * 100).toStringAsFixed(1)}%'),
            Text('${(transfer.bytesSent / (1024 * 1024)).toStringAsFixed(1)} / ${(transfer.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'),
          ],
        ),
      ],
    );
  }

  Widget _buildTransferInfo(TransferProgress transfer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '${transfer.speed.toStringAsFixed(2)} KB/s',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer?'),
        content: const Text('Are you sure you want to stop the current file transfer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Transfer'),
          ),
          TextButton(
            onPressed: () {
              // Implementation for cancel logic would go here in Ref
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
