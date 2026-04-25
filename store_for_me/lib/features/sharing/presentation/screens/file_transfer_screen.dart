import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sharing_provider.dart';
import '../../data/models/sharing_models.dart';

class FileTransferScreen extends ConsumerStatefulWidget {
  final PeerDevice? device;
  final List<File>? files;
  final String? myName;

  const FileTransferScreen({
    super.key,
    this.device,
    this.files,
    this.myName,
  });

  @override
  ConsumerState<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends ConsumerState<FileTransferScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.device != null && widget.files != null && widget.myName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sharingProvider.notifier).sendFilesToDevice(
          widget.device!,
          widget.files!,
          widget.myName!,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharingProvider);
    final transfers = state.activeTransfers.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('File Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_allCompleted(transfers)) {
              ref.read(sharingProvider.notifier).resetTransfer();
              Navigator.pop(context);
            } else {
              _showCancelDialog(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildSessionHeader(transfers),
          Expanded(
            child: transfers.isEmpty
                ? const Center(child: Text('Waiting for transfer to start...'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transfers.length,
                    itemBuilder: (context, index) {
                      final transfer = transfers[index];
                      return _buildTransferCard(transfer);
                    },
                  ),
          ),
          if (_allCompleted(transfers) && transfers.isNotEmpty)
            _buildActionFooter(),
        ],
      ),
    );
  }

  bool _allCompleted(List<TransferProgress> transfers) {
    if (transfers.isEmpty) return true;
    return transfers.every((t) => 
        t.status == TransferStatus.completed || t.status == TransferStatus.failed);
  }

  Widget _buildSessionHeader(List<TransferProgress> transfers) {
    final firstTransfer = transfers.isNotEmpty ? transfers.first : null;
    final peerName = firstTransfer?.peerName ?? (widget.device?.name ?? 'Connecting...');
    final isUpload = firstTransfer?.type == TransferType.upload || widget.files != null;

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary.withAlpha(10),
      child: Row(
        children: [
          Icon(
            isUpload ? Icons.upload_rounded : Icons.download_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpload ? 'Sending to $peerName' : 'Receiving from $peerName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${transfers.length} files in session',
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

  Widget _buildTransferCard(TransferProgress transfer) {
    final isDone = transfer.status == TransferStatus.completed;
    final isFailed = transfer.status == TransferStatus.failed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone ? AppColors.success.withAlpha(100) : AppColors.divider.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    '${transfer.speed.toStringAsFixed(1)} KB/s',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: transfer.progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: AppColors.divider.withAlpha(100),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.success : (isFailed ? AppColors.error : AppColors.primary),
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
        return const Icon(Icons.check_circle, color: AppColors.success, size: 20);
      case TransferStatus.failed:
        return const Icon(Icons.error, color: AppColors.error, size: 20);
      default:
        return const Icon(Icons.sync, color: AppColors.primary, size: 20);
    }
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(sharingProvider.notifier).resetTransfer();
                  Navigator.pop(context);
                },
                child: const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer?'),
        content: const Text('Are you sure you want to stop the current sharing session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Stop Session', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
