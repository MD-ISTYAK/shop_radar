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

class _FileTransferScreenState extends ConsumerState<FileTransferScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

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
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  bool _allCompleted(List<TransferProgress> transfers) {
    if (transfers.isEmpty) return true;
    return transfers
        .every((t) => t.status == TransferStatus.completed || t.status == TransferStatus.failed);
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharingProvider);
    final transfers = state.activeTransfers.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    final allDone = _allCompleted(transfers);
    final isUpload = transfers.isEmpty || transfers.first.type == TransferType.upload;
    final peerName = transfers.isNotEmpty
        ? (transfers.first.peerName ?? widget.device?.name ?? 'Device')
        : (widget.device?.name ?? 'Connecting...');

    // Overall progress
    int totalBytes = 0, sentBytes = 0;
    for (final t in transfers) {
      totalBytes += t.totalBytes;
      sentBytes += t.bytesSent;
    }
    final overallProgress =
        totalBytes > 0 ? sentBytes / totalBytes : (transfers.isEmpty ? 0.0 : 1.0);
    final avgSpeed = transfers.isEmpty
        ? 0.0
        : transfers.map((t) => t.speed).reduce((a, b) => a + b) / transfers.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (allDone) {
              ref.read(sharingProvider.notifier).resetTransfer();
              Navigator.pop(context);
            } else {
              _showCancelDialog(context);
            }
          },
        ),
        title: Text(
          isUpload ? 'Sending...' : 'Receiving...',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Overall progress section
          _buildOverallProgress(
            context,
            isUpload: isUpload,
            peerName: peerName,
            progress: overallProgress.toDouble(),
            speed: avgSpeed,
            allDone: allDone,
            transfers: transfers,
          ),

          // File list
          Expanded(
            child: transfers.isEmpty
                ? _buildWaitingState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transfers.length,
                    itemBuilder: (_, i) => _buildTransferCard(transfers[i]),
                  ),
          ),

          if (allDone && transfers.isNotEmpty) _buildSuccessFooter(context, transfers),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF16A34A).withAlpha(
                      ((_waveController.value * 60) + 15).toInt()),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 48,
                  color: Color(0xFF16A34A),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Connecting to device...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please keep this screen open',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(
    BuildContext context, {
    required bool isUpload,
    required String peerName,
    required double progress,
    required double speed,
    required bool allDone,
    required List<TransferProgress> transfers,
  }) {
    final color = isUpload ? const Color(0xFF16A34A) : const Color(0xFF3B82F6);
    final completed = transfers.where((t) => t.status == TransferStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUpload ? Icons.send_rounded : Icons.download_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUpload ? 'Sending to $peerName' : 'Receiving from $peerName',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      allDone
                          ? '$completed/${transfers.length} files completed'
                          : '${transfers.length} file(s) • ${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!allDone)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              if (allDone)
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                  allDone ? AppColors.success : color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(TransferProgress transfer) {
    final isDone = transfer.status == TransferStatus.completed;
    final isFailed = transfer.status == TransferStatus.failed;
    final isActive = !isDone && !isFailed;
    final progressColor = isDone
        ? AppColors.success
        : isFailed
            ? AppColors.error
            : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? AppColors.success.withAlpha(60)
              : isFailed
                  ? AppColors.error.withAlpha(60)
                  : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : isFailed
                        ? Icons.error_rounded
                        : Icons.insert_drive_file_rounded,
                color: progressColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      isActive
                          ? '${_fmt(transfer.bytesSent)} / ${_fmt(transfer.totalBytes)}'
                          : _fmt(transfer.totalBytes),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Text(
                  '${(transfer.speed / (1024 * 1024)).toStringAsFixed(1)} MB/s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isFailed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Failed',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: transfer.progress,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessFooter(
      BuildContext context, List<TransferProgress> transfers) {
    final failedCount =
        transfers.where((t) => t.status == TransferStatus.failed).length;
    final successCount = transfers.length - failedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  '$successCount/${transfers.length} Transfer Completed',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(sharingProvider.notifier).resetTransfer();
                      Navigator.of(context)
                          .popUntil((r) => r.settings.name == '/sharing');
                    },
                    child: const Text('Go Home'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(sharingProvider.notifier).resetTransfer();
                      Navigator.pushNamed(context, '/sharing/history');
                    },
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('History'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A)),
                  ),
                ),
              ],
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
        content: const Text(
            'Are you sure you want to stop the current sharing session?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(sharingProvider.notifier).resetTransfer();
              Navigator.pop(context);
            },
            child: const Text('Stop Session',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
