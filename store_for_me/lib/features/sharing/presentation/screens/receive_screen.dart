import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/sharing_provider.dart';
import '../../data/models/sharing_models.dart';
import '../../../../presentation/providers/auth_provider.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen>
    with TickerProviderStateMixin {
  bool _permissionsGranted = false;
  late AnimationController _pulseController;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    List<Permission> permissions = [];
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.storage,
        Permission.photos,
        Permission.location,
        Permission.nearbyWifiDevices,
      ]);
    }
    final statuses = await permissions.request();

    bool granted = true;
    if (Platform.isAndroid) {
      final loc = await Permission.location.isGranted;
      final storage = await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted;
      granted = loc && storage;
    }

    if (mounted) setState(() => _permissionsGranted = granted);

    if (granted) {
      _initReceive();
    } else {
      bool anyPerm = statuses.values.any((s) => s.isPermanentlyDenied);
      if (anyPerm && mounted) {
        Navigator.pushReplacementNamed(context, '/sharing/permissions');
      }
    }
  }

  void _initReceive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final myName = authState.user?.name ?? 'File Share User';
      ref.read(sharingProvider.notifier).startReceiveMode(myName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharingProvider);
    final transfers = state.activeTransfers.values
        .where((t) => t.type == TransferType.download)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (transfers.isNotEmpty && !_allCompleted(transfers)) {
              _showExitDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Receive', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (state.isReceiving)
            TextButton(
              onPressed: () =>
                  ref.read(sharingProvider.notifier).stopReceiveMode(),
              child: const Text('Stop',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: transfers.isEmpty
          ? _buildWaitingUI(state)
          : _buildTransferUI(state, transfers),
    );
  }

  bool _allCompleted(List<TransferProgress> transfers) {
    if (transfers.isEmpty) return false;
    return transfers.every((t) =>
        t.status == TransferStatus.completed ||
        t.status == TransferStatus.failed);
  }

  Widget _buildWaitingUI(SharingState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: state.isReceiving
                  ? AppColors.success.withAlpha(20)
                  : AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state.isReceiving
                    ? AppColors.success.withAlpha(60)
                    : AppColors.error.withAlpha(60),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isReceiving
                        ? AppColors.success
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.isReceiving
                      ? 'Discoverable — Waiting for sender...'
                      : 'Receive mode OFF',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: state.isReceiving
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Radar animation
          _buildRadarAnimation(state),
          const SizedBox(height: 40),

          // Device info
          _buildDeviceCard(),
          const SizedBox(height: 20),

          // QR code
          _buildQrSection(),

          if (!_permissionsGranted) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/sharing/permissions'),
                icon: const Icon(Icons.security_rounded),
                label: const Text('Grant Permissions'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRadarAnimation(SharingState state) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated rings
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final progress = (_pulseController.value + i / 3) % 1.0;
                return Opacity(
                  opacity: (1 - progress) * 0.4,
                  child: Transform.scale(
                    scale: 0.4 + progress * 0.6,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Radar sweep
          if (state.isReceiving)
            AnimatedBuilder(
              animation: _radarController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _RadarPainter(
                    angle: _radarController.value * 2 * pi,
                    color: const Color(0xFF3B82F6),
                  ),
                  size: const Size(200, 200),
                );
              },
            ),
          // Center icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withAlpha(80),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard() {
    final authState = ref.read(authProvider);
    final deviceName = authState.user?.name ?? 'File Share User';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_android_rounded,
                color: Color(0xFF3B82F6), size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Device',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(
                deviceName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text(
            'Scan to Connect',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ask sender to scan this QR code',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: 'fileshare://receive?device=MyDevice&port=5555',
            version: QrVersions.auto,
            size: 140,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTransferUI(
      SharingState state, List<TransferProgress> transfers) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF3B82F6).withAlpha(15),
          child: Row(
            children: [
              const Icon(Icons.download_rounded, color: Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receiving from ${transfers.first.peerName ?? "Unknown"}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${transfers.length} file(s)',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!_allCompleted(transfers))
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transfers.length,
            itemBuilder: (context, index) =>
                _buildTransferCard(transfers[index]),
          ),
        ),
        if (_allCompleted(transfers)) _buildSuccessFooter(),
      ],
    );
  }

  Widget _buildTransferCard(TransferProgress transfer) {
    final isDone = transfer.status == TransferStatus.completed;
    final isFailed = transfer.status == TransferStatus.failed;
    final progressColor = isDone
        ? AppColors.success
        : isFailed
            ? AppColors.error
            : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? AppColors.success.withAlpha(80)
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
                        : Icons.downloading_rounded,
                color: progressColor,
                size: 24,
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_fmt(transfer.bytesSent)} / ${_fmt(transfer.totalBytes)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!isDone && !isFailed)
                Text(
                  '${(transfer.speed / (1024 * 1024)).toStringAsFixed(1)} MB/s',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: transfer.progress,
              minHeight: 7,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (!isDone && !isFailed) ...[
            const SizedBox(height: 6),
            Text(
              '${(transfer.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Widget _buildSuccessFooter() {
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
              children: const [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text(
                  'Transfer Completed Successfully!',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.success),
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
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
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
                    label: const Text('View History'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Receiving?'),
        content: const Text(
            'A transfer is in progress. Leaving might interrupt it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Stop & Exit',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// Radar painter
class _RadarPainter extends CustomPainter {
  final double angle;
  final Color color;

  _RadarPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw sweep gradient
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - pi / 3,
        endAngle: angle,
        colors: [
          Colors.transparent,
          color.withAlpha(80),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    // Draw sweep line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
