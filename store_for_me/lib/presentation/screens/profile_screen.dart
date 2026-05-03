import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/gamification_provider.dart';
import '../widgets/premium_widgets.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === PREMIUM HEADER ===
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Cover Photo Placeholder
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                // Header Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 150, 20, 0),
                  child: Column(
                    children: [
                      PremiumAvatar(
                        imageUrl: user?.avatar != null ? AppConstants.getImageUrl(user!.avatar) : null,
                        size: 100,
                      ).animate().scale(duration: 400.ms),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'User',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '@${user?.username ?? 'username'}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsBar(user, gamState),
                      const SizedBox(height: 20),
                      PremiumButton(
                        text: 'Edit Profile',
                        onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                        width: 140,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === WALLET CARD ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildWalletCard(walletState, isDark),
            ),
          ),

          // === BADGES SECTION ===
          if (gamState.badges.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildBadgesSection(gamState),
            ),

          // === MENU ITEMS ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMenuSection('Business', [
                  _buildMenuItem(Icons.rocket_launch_rounded, 'Start Your Business', () => Navigator.pushNamed(context, '/start-business')),
                  if (user?.hasBusinessAccount == true)
                    _buildMenuItem(Icons.business_center_rounded, 'My Businesses', () => Navigator.pushNamed(context, '/my-businesses')),
                  if (user?.isOwner == true)
                    _buildMenuItem(Icons.dashboard_rounded, 'Owner Dashboard', () => Navigator.pushNamed(context, '/owner-dashboard')),
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('Social & Orders', [
                  _buildMenuItem(Icons.delivery_dining_rounded, 'Delivery Partner', () => Navigator.pushNamed(context, '/delivery-partner')),
                  _buildMenuItem(Icons.favorite_rounded, 'Followed Shops', () => Navigator.pushNamed(context, '/followed-shops')),
                  _buildMenuItem(Icons.shopping_bag_rounded, 'My Orders', () {}),
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('Settings', [
                  _buildMenuItem(Icons.settings_rounded, 'App Settings', () => Navigator.pushNamed(context, '/settings')),
                  _buildMenuItem(Icons.logout_rounded, 'Logout', () async {
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/login');
                  }, isDestructive: true),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(dynamic user, dynamic gamState) {
    return PremiumGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('${user?.totalCheckIns ?? 0}', 'Check-ins'),
          _buildDivider(),
          _buildStatItem('${user?.totalOrders ?? 0}', 'Orders'),
          _buildDivider(),
          _buildStatItem('${gamState.earnedCount}', 'Badges'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: AppColors.textLight.withOpacity(0.2));
  }

  Widget _buildWalletCard(dynamic walletState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBackground, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wallet Balance',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.cyanAccent, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${walletState.balance.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildWalletButton('Add Money', Icons.add_rounded, () {}),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWalletButton('History', Icons.history_rounded, () => Navigator.pushNamed(context, '/wallet')),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildWalletButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(dynamic gamState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Badges',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/badges'),
                child: Text('See All', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: gamState.badges.length,
            itemBuilder: (context, index) {
              final badge = gamState.badges[index];
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                child: PremiumGlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppConstants.badgeEmoji[badge.badgeName] ?? '🏅', style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        badge.badgeName.replaceAll('_', ' '),
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textLight),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.textLight.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
      onTap: onTap,
    );
  }
}





