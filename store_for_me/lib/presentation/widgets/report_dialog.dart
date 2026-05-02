import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/social_provider.dart';

/// A premium bottom sheet dialog for reporting content.
/// Supports posts, reels, stories, comments, and users.
class ReportDialog extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType; // 'post', 'reel', 'story', 'comment', 'user'
  final VoidCallback? onReported;

  const ReportDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    this.onReported,
  });

  /// Show the report dialog as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String targetId,
    required String targetType,
    VoidCallback? onReported,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDialog(
        targetId: targetId,
        targetType: targetType,
        onReported: onReported,
      ),
    );
  }

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  static const _reasons = [
    _ReportReason(
      value: 'copyright',
      label: 'Copyright Violation',
      icon: Icons.copyright_rounded,
      description: 'Uses copyrighted music, video, or other content',
    ),
    _ReportReason(
      value: 'inappropriate',
      label: 'Inappropriate Content',
      icon: Icons.block_rounded,
      description: 'Nudity, violence, or disturbing content',
    ),
    _ReportReason(
      value: 'spam',
      label: 'Spam',
      icon: Icons.report_gmailerrorred_rounded,
      description: 'Misleading, repetitive, or unwanted content',
    ),
    _ReportReason(
      value: 'harassment',
      label: 'Harassment',
      icon: Icons.person_off_rounded,
      description: 'Bullying, threats, or targeted abuse',
    ),
    _ReportReason(
      value: 'hate_speech',
      label: 'Hate Speech',
      icon: Icons.do_not_touch_rounded,
      description: 'Promotes hatred against a group or individual',
    ),
    _ReportReason(
      value: 'misinformation',
      label: 'False Information',
      icon: Icons.fact_check_outlined,
      description: 'Fake news or misleading claims',
    ),
    _ReportReason(
      value: 'scam',
      label: 'Scam / Fraud',
      icon: Icons.warning_amber_rounded,
      description: 'Attempting to deceive or defraud users',
    ),
    _ReportReason(
      value: 'other',
      label: 'Other',
      icon: Icons.more_horiz_rounded,
      description: 'Something else not listed above',
    ),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(socialProvider.notifier).reportContent(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _selectedReason!,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
      widget.onReported?.call();
      // Auto-dismiss after showing success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. You may have already reported this content.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: _submitted ? _buildSuccessState(isDark) : _buildReportForm(isDark),
      ),
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
          ),
          const SizedBox(height: 20),
          Text(
            'Report Submitted',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for helping keep our community safe.\nWe\'ll review this content shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportForm(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Why are you reporting this ${widget.targetType}?',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white54 : AppColors.textLight),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Reason list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _reasons.length,
            itemBuilder: (context, index) {
              final reason = _reasons[index];
              final isSelected = _selectedReason == reason.value;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: Material(
                  color: isSelected
                      ? (isDark ? AppColors.primary.withAlpha(30) : AppColors.primary.withAlpha(15))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedReason = reason.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            reason.icon,
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white54 : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reason.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? Colors.white : AppColors.textPrimary),
                                  ),
                                ),
                                Text(
                                  reason.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white38 : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : (isDark ? Colors.white24 : Colors.grey[300]!),
                                width: 2,
                              ),
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Description field (shown when a reason is selected)
        if (_selectedReason != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedOpacity(
              opacity: _selectedReason != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: TextField(
                controller: _descriptionController,
                maxLines: 2,
                maxLength: 500,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add more details (optional)',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : AppColors.textLight,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  counterStyle: TextStyle(
                    color: isDark ? Colors.white24 : AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),

        // Submit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedReason != null && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  disabledBackgroundColor: isDark ? Colors.white.withAlpha(10) : Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportReason {
  final String value;
  final String label;
  final IconData icon;
  final String description;

  const _ReportReason({
    required this.value,
    required this.label,
    required this.icon,
    required this.description,
  });
}
