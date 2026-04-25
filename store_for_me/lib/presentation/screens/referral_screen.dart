import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../providers/gamification_provider.dart';
import '../widgets/common_widgets.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(gamificationProvider.notifier).fetchReferrals());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamState = ref.watch(gamificationProvider);
    final referral = gamState.referral;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, const Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  const Text('Get ₹50 for every friend!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Your friend gets ₹50 too!', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14)),
                  const SizedBox(height: 20),
                  // Referral code
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          referral?.referralCode ?? '...',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 3),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Share.share('Join Shop Radar using my code: ${referral?.referralCode ?? ''} and get ₹50! Download now.'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.share, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05),

            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                _buildReferralStat('${referral?.totalReferrals ?? 0}', 'Total Referrals'),
                const SizedBox(width: 12),
                _buildReferralStat('${referral?.completedReferrals ?? 0}', 'Completed'),
                const SizedBox(width: 12),
                _buildReferralStat('₹${(referral?.totalRewards ?? 0).toInt()}', 'Earned'),
              ],
            ),
            const SizedBox(height: 24),

            // Apply code section
            const Text('Have a referral code?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Enter referral code',
                      prefixIcon: const Icon(Icons.card_giftcard),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_codeController.text.isEmpty) return;
                    final result = await ref.read(gamificationProvider.notifier).applyReferralCode(_codeController.text.trim());
                    if (result && mounted) {
                      _codeController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('🎉 ₹50 added to your wallet!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Referral list
            if (referral != null && referral.referrals.isNotEmpty) ...[
              const Text('Your Referrals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...referral.referrals.map((r) {
                final statusColor = r.status == 'rewarded' ? AppColors.success : AppColors.warning;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(20),
                    child: Text(r.refereeName.isNotEmpty ? r.refereeName[0] : '?', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  title: Text(r.refereeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}', style: const TextStyle(fontSize: 12)),
                  trailing: StatusBadge(status: r.status.toUpperCase(), color: statusColor),
                );
              }),
            ],

            // How it works
            const SizedBox(height: 24),
            const Text('How it Works', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _buildStep('1', 'Share your code', 'Send your unique code to friends'),
            _buildStep('2', 'Friend signs up', 'They enter your code during registration'),
            _buildStep('3', 'Both earn ₹50!', 'Instantly credited to wallets'),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(number, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ],
      ),
    );
  }
}









