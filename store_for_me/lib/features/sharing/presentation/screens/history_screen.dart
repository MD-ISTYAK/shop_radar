import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showReceived = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: history.isEmpty
                ? null
                : () => _showClearDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(
              width: 3,
              color: Color(0xFF16A34A),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          labelColor: const Color(0xFF16A34A),
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Apps'),
            Tab(text: 'Videos'),
            Tab(text: 'Photos'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Received / Sent Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleChip(
                    label: 'Receive',
                    icon: Icons.download_rounded,
                    isSelected: _showReceived,
                    color: const Color(0xFF16A34A),
                    onTap: () => setState(() => _showReceived = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToggleChip(
                    label: 'Send',
                    icon: Icons.send_rounded,
                    isSelected: !_showReceived,
                    color: const Color(0xFF3B82F6),
                    onTap: () => setState(() => _showReceived = false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(history, null),
                _buildList(history, 'app'),
                _buildList(history, 'video'),
                _buildList(history, 'photo'),
                _buildList(history, 'file'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<HistoryItem> history, String? typeFilter) {
    var filtered = history.where((item) {
      final matchType = _showReceived ? !item.isSent : item.isSent;
      final matchCategory =
          typeFilter == null || item.fileType == typeFilter;
      return matchType && matchCategory;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 72, color: AppColors.divider),
            const SizedBox(height: 16),
            const Text(
              'No history yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Files you send or receive will appear here.',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(context, filtered[index]);
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item) {
    final isSuccess = item.status == 'success';
    final color = item.isSent
        ? const Color(0xFF3B82F6)
        : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File Type Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getTypeIcon(item.fileType), color: color, size: 26),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatSize(item.sizeBytes),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      const Text(' • ',
                          style: TextStyle(
                              color: AppColors.textSecondary)),
                      Text(
                        item.isSent ? 'To: ${item.peerName}' : 'From: ${item.peerName}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(item.timestamp),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? AppColors.success.withAlpha(20)
                        : AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSuccess ? 'Success' : 'Failed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSuccess
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  iconSize: 20,
                  onSelected: (val) =>
                      _handleAction(context, val, item),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(children: [
                        Icon(Icons.open_in_new_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Open'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(children: [
                        Icon(Icons.share_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Share Again'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'app':
        return Icons.android_rounded;
      case 'video':
        return Icons.movie_rounded;
      case 'photo':
        return Icons.image_rounded;
      case 'music':
        return Icons.music_note_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  void _handleAction(
      BuildContext context, String action, HistoryItem item) {
    switch (action) {
      case 'delete':
        ref.read(historyProvider.notifier).removeItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History item deleted')),
        );
        break;
      case 'open':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${item.fileName}...')),
        );
        break;
      case 'share':
        Navigator.pushNamed(context, '/sharing');
        break;
    }
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('This will delete all transfer history. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
