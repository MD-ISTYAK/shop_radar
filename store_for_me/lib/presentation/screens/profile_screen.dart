import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/gamification_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchWallet();
      ref.read(gamificationProvider.notifier).fetchBadges();
      ref.read(gamificationProvider.notifier).fetchReferrals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final gamState = ref.watch(gamificationProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withAlpha(40),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatar.isNotEmpty == true 
                          ? CachedNetworkImageProvider(AppConstants.getImageUrl(user!.avatar))
                          : null,
                      child: (user?.avatar.isEmpty == true)
                          ? Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary),
                            )
                          : null,
                    ),
                  ).animate().scale(duration: 400.ms),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                   if (user?.username != null && user!.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('@${user.username}', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                  if (user?.bio != null && user!.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        user.bio, 
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('${user?.totalCheckIns ?? 0}', 'Check-ins'),
                      Container(height: 30, width: 1, color: Colors.white.withAlpha(40)),
                      _buildStat('${user?.totalReviews ?? 0}', 'Reviews'),
                      Container(height: 30, width: 1, color: Colors.white.withAlpha(40)),
                      _buildStat('${user?.totalOrders ?? 0}', 'Orders'),
                      Container(height: 30, width: 1, color: Colors.white.withAlpha(40)),
                      _buildStat('${gamState.earnedCount}', 'Badges'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Wallet Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF1E293B), const Color(0xFF334155)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/wallet'),
                          child: const Text('View All', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${walletState.balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                    ).animate().fadeIn(duration: 600.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('+ Add Money', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Withdraw', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
            ),
          ),

          // Referral Card
          if (gamState.referral != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withAlpha(50)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.card_giftcard, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Refer & Earn ₹50', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('Your code: ${gamState.referral!.referralCode}',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.primary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Badges preview
          if (gamState.badges.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('My Badges', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        TextButton(onPressed: () => Navigator.pushNamed(context, '/badges'), child: const Text('View All')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: gamState.badges.length.clamp(0, 6),
                        itemBuilder: (context, index) {
                          final badge = gamState.badges[index];
                          final emoji = AppConstants.badgeEmoji[badge.badgeName] ?? '🏅';
                          return Container(
                            width: 72,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: badge.earned ? AppColors.primary.withAlpha(15) : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: badge.earned ? AppColors.primary.withAlpha(50) : Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(emoji, style: TextStyle(fontSize: 24, color: badge.earned ? null : Theme.of(context).textTheme.bodySmall?.color)),
                                SizedBox(height: 4),
                                Text(
                                  badge.badgeName.replaceAll('_', ' '),
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600,
                                    color: badge.earned ? AppColors.primary : Theme.of(context).textTheme.bodySmall?.color),
                                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Menu Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  _buildMenuItem(Icons.rocket_launch, 'Start Your Business', () => Navigator.pushNamed(context, '/start-business')),
                  if (user?.hasBusinessAccount == true)
                    _buildMenuItem(Icons.business_center, 'My Businesses', () => Navigator.pushNamed(context, '/my-businesses')),
                  if (user?.isOwner == true)
                    _buildMenuItem(Icons.dashboard, 'Owner Dashboard', () => Navigator.pushNamed(context, '/owner-dashboard')),
                  _buildMenuItem(Icons.delivery_dining, 'Delivery Partner', () => Navigator.pushNamed(context, '/delivery-partner')),
                  _buildMenuItem(Icons.favorite_outline, 'Followed Shops', () => Navigator.pushNamed(context, '/followed-shops')),
                  _buildMenuItem(Icons.shopping_bag_outlined, 'My Orders', () {}),
                  _buildMenuItem(Icons.rate_review_outlined, 'My Reviews', () {}),
                  _buildMenuItem(Icons.location_on_outlined, 'My Check-ins', () {}),
                  _buildMenuItem(Icons.local_offer_outlined, 'Saved Deals', () {}),
                  _buildMenuItem(Icons.settings_outlined, 'Settings', () => Navigator.pushNamed(context, '/settings')),
                  const SizedBox(height: 8),
                  _buildMenuItem(Icons.logout, 'Logout', () async {
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/login');
                  }, isDestructive: true),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(160))),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : Theme.of(context).textTheme.bodyMedium?.color, size: 22),
      title: Text(label, style: TextStyle(
        fontWeight: FontWeight.w500,
        color: isDestructive ? AppColors.error : Theme.of(context).textTheme.bodyLarge?.color,
      )),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}




