import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/data_saver_provider.dart';

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
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = authState.user;

    final userLevel = ((user?.totalCheckIns ?? 0) / 5).floor() + 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Profile Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              child: Column(
                children: [
                  // Avatar with Edit Button Overlay
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withAlpha(40),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.avatar.isNotEmpty == true
                              ? CachedNetworkImageProvider(
                                  AppConstants.getImageUrl(user!.avatar))
                              : null,
                          child: (user?.avatar.isEmpty == true)
                              ? Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 400.ms),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  if (user?.username != null && user!.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // User Rank / Level Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Local Explorer • Lvl $userLevel',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (user?.bio != null && user!.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        user.bio,
                        style: TextStyle(
                            color: Colors.white.withAlpha(190), fontSize: 13),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Interactive Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(
                        '${user?.totalCheckIns ?? 0}',
                        'Check-ins',
                        onTap: () => _showCheckInsSheet(context, user),
                      ),
                      Container(
                          height: 28,
                          width: 1,
                          color: Colors.white.withAlpha(40)),
                      _buildStat(
                        '${user?.totalReviews ?? 0}',
                        'Reviews',
                        onTap: () => _showReviewsSheet(context, user),
                      ),
                      Container(
                          height: 28,
                          width: 1,
                          color: Colors.white.withAlpha(40)),
                      _buildStat(
                        '${user?.totalOrders ?? 0}',
                        'Orders',
                        onTap: () => Navigator.pushNamed(context, '/orders'),
                      ),
                      Container(
                          height: 28,
                          width: 1,
                          color: Colors.white.withAlpha(40)),
                      _buildStat(
                        '${gamState.earnedCount}',
                        'Badges',
                        onTap: () => Navigator.pushNamed(context, '/badges'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Wallet Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: Colors.cyanAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Shop Radar Wallet',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text('Cashback & Refunds',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/wallet'),
                          icon: const Icon(Icons.history,
                              color: Colors.cyanAccent, size: 16),
                          label: const Text('History',
                              style: TextStyle(
                                  color: Colors.cyanAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${walletState.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddMoneySheet(context),
                            icon: const Icon(Icons.add_circle_outline,
                                size: 16),
                            label: const Text('+ Add Money',
                                style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showWithdrawSheet(
                                context, walletState.balance),
                            icon: const Icon(Icons.north_east, size: 16),
                            label: const Text('Withdraw',
                                style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
            ),
          ),

          // 3. Referral Card
          if (gamState.referral != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(25),
                        AppColors.primary.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withAlpha(50)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.card_giftcard,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Refer Friends & Earn ₹50',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Code: ${gamState.referral!.referralCode}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: gamState
                                            .referral!.referralCode));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Referral code copied to clipboard!')),
                                    );
                                  },
                                  child: const Icon(Icons.copy,
                                      size: 14, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final code = gamState.referral!.referralCode;
                          Share.share(
                            'Join Shop Radar using my referral code "$code" and get ₹50 cashback! Download now: https://shopradar.app',
                          );
                        },
                        icon: const Icon(Icons.share, size: 14),
                        label: const Text('Share', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Badges Section
          if (gamState.badges.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('My Badges & Rewards',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/badges'),
                          child: const Text('View All',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: gamState.badges.length.clamp(0, 6),
                        itemBuilder: (context, index) {
                          final badge = gamState.badges[index];
                          final emoji =
                              AppConstants.badgeEmoji[badge.badgeName] ?? '🏅';
                          return Container(
                            width: 76,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: badge.earned
                                  ? AppColors.primary.withAlpha(15)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: badge.earned
                                    ? AppColors.primary.withAlpha(50)
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  emoji,
                                  style: TextStyle(
                                      fontSize: 24,
                                      color: badge.earned
                                          ? null
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  badge.badgeName.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: badge.earned
                                        ? AppColors.primary
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

          // 5. Categorized Options & Settings Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  _buildBusinessOwnerCard(context, user),

                  if (user?.isDeliveryPartner == true)
                    _buildDeliveryPartnerCard(context, user),

                  // --- Group 1: Business Radar Hub ---
                  _buildSectionHeader('Business Radar Hub'),
                  _buildSectionCard([
                    _buildTile(
                      icon: Icons.storefront_outlined,
                      title: 'My Registered Businesses',
                      subtitle: 'Manage shops, carts & services',
                      onTap: () =>
                          Navigator.pushNamed(context, '/my-businesses'),
                    ),
                    _buildTile(
                      icon: Icons.dashboard_outlined,
                      title: 'Business Manager Dashboard',
                      subtitle: 'Manage inventory, items, live orders & queue',
                      onTap: () =>
                          Navigator.pushNamed(context, '/owner-dashboard'),
                    ),
                    _buildTile(
                      icon: Icons.rocket_launch_outlined,
                      title: 'Register Business (Business Radar)',
                      subtitle: 'List shop, street cart, tea stall or repair service',
                      onTap: () =>
                          Navigator.pushNamed(context, '/add-shop'),
                    ),
                    _buildTile(
                      icon: Icons.delivery_dining_outlined,
                      title: 'Delivery Partner Portal',
                      subtitle: 'Earn money delivering local orders',
                      onTap: () =>
                          Navigator.pushNamed(context, '/delivery-partner'),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // --- Group 2: Shopping & Wallet Activity ---
                  _buildSectionHeader('Shopping & Wallet Activity'),
                  _buildSectionCard([
                    _buildTile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      subtitle: 'Track active & past purchases',
                      onTap: () => Navigator.pushNamed(context, '/orders'),
                    ),
                    _buildTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet & Cashbacks',
                      subtitle: 'Deposit funds, check balance & rewards',
                      onTap: () => Navigator.pushNamed(context, '/wallet'),
                    ),
                    _buildTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Saved Deals & Offers',
                      subtitle: 'Discounts & active coupons',
                      onTap: () => Navigator.pushNamed(context, '/deals'),
                    ),
                    _buildTile(
                      icon: Icons.favorite_outline,
                      title: 'Followed Businesses',
                      subtitle: 'Shops & services you follow',
                      onTap: () =>
                          Navigator.pushNamed(context, '/followed-shops'),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // --- Group 3: Integrated App Controls & Preferences ---
                  _buildSectionHeader('App Preferences & Controls'),
                  _buildSectionCard([
                    _buildTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: isDark ? 'Dark theme enabled' : 'Light theme enabled',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) => ref
                            .read(themeProvider.notifier)
                            .toggleTheme(val),
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                    Consumer(builder: (context, ref, _) {
                      final isDataSaver = ref.watch(dataSaverProvider);
                      return _buildTile(
                        icon: Icons.data_usage_outlined,
                        title: 'Data Saver Mode',
                        subtitle: isDataSaver ? 'Low bandwidth mode active' : 'High quality media active',
                        trailing: Switch(
                          value: isDataSaver,
                          onChanged: (val) => ref.read(dataSaverProvider.notifier).toggle(),
                          activeThumbColor: AppColors.primary,
                        ),
                      );
                    }),
                    _buildTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: AppConstants.supportedLanguages[
                              ref.watch(localeProvider)] ??
                          'English',
                      onTap: () => _showLanguageSheet(context, ref),
                    ),
                    _buildTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage alerts & push updates',
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
                    ),
                    _buildTile(
                      icon: Icons.help_outline,
                      title: 'Help, FAQ & Support',
                      subtitle: '24/7 helpline, privacy & terms',
                      onTap: () => _showHelpSupportModal(context),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // --- Group 4: Account Actions ---
                  _buildSectionCard([
                    _buildTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out from Business Radar',
                      isDestructive: true,
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                    _buildTile(
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete account & data',
                      isDestructive: true,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Business Radar v2.5.0 • Solving Issues for All Businesses 📡',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildStat(String value, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withAlpha(170)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodySmall?.color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> tiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          return Column(
            children: [
              tiles[index],
              if (index < tiles.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  endIndent: 12,
                  color: isDark ? Colors.white12 : Colors.grey.withAlpha(30),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive
        ? AppColors.error
        : Theme.of(context).textTheme.bodyLarge?.color;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withAlpha(20)
              : AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDestructive
                    ? AppColors.error.withAlpha(160)
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).textTheme.bodySmall?.color)
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: false,
    );
  }

  // --- Modal Sheets & Dialogs ---

  void _showHelpSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Help & Support Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.support_agent, color: AppColors.primary),
                title: Text('24/7 Customer Support'),
                subtitle: Text('Email: support@businessradar.app | Phone: +91 1800-123-7467'),
              ),
              const ListTile(
                leading: Icon(Icons.policy_outlined, color: AppColors.primary),
                title: Text('Privacy & Security'),
                subtitle: Text('All local user and business transactions are encrypted.'),
              ),
              const ListTile(
                leading: Icon(Icons.description_outlined, color: AppColors.primary),
                title: Text('Terms of Service'),
                subtitle: Text('Governs local buying, selling, cart services & deliveries.'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
        content: const Text(
          'WARNING: Permanently deleting your account will erase all active orders, registered businesses, and wallet balance. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion request received. Our support team will process it within 24 hours.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddMoneySheet(BuildContext context) {
    final controller = TextEditingController(text: '500');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Add Money to Wallet',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Enter Amount',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['100', '500', '1000', '2000'].map((amt) {
                  return ActionChip(
                    label: Text('+$amt'),
                    onPressed: () => controller.text = amt,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text) ?? 0;
                    if (amount <= 0) return;
                    Navigator.pop(ctx);
                    final success = await ref
                        .read(walletProvider.notifier)
                        .addMoney(amount, 'ADD_${DateTime.now().millisecondsSinceEpoch}');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? '₹${amount.toStringAsFixed(0)} added successfully!'
                              : 'Failed to add money.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Proceed to Add Money',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawSheet(BuildContext context, double balance) {
    final upiController = TextEditingController();
    final amountController =
        TextEditingController(text: balance.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Withdraw to UPI / Bank',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Available Balance: ₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Withdrawal Amount',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: upiController,
                decoration: InputDecoration(
                  labelText: 'UPI ID (e.g. mobile@upi)',
                  hintText: 'user@paytm / user@okaxis',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountController.text) ?? 0;
                    if (amt <= 0 || amt > balance || upiController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Invalid amount or UPI ID. Please check.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Withdrawal request for ₹${amt.toStringAsFixed(0)} submitted!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Request Payout',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewsSheet(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('My Reviews & Feedback',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber, size: 28),
                title: Text('${user?.totalReviews ?? 0} Reviews Published',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text(
                    'You have earned "Verified Reviewer" badge on Shop Radar.'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/discover');
                  },
                  child: const Text('Review Nearby Shops'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCheckInsSheet(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('My Check-ins & Places',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.location_on,
                    color: AppColors.primary, size: 28),
                title: Text('${user?.totalCheckIns ?? 0} Total Check-ins',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text(
                    'Every check-in earns points towards local badges & rewards!'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/map-view');
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Explore Nearby Radar Map'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(localeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Select Language (भाषा चुनें)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...AppConstants.supportedLanguages.entries.map((e) {
              final isSelected = currentLang == e.key;
              return ListTile(
                title: Text(e.value,
                    style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : null)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(localeProvider.notifier).setLocale(e.key);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ App language set to ${e.value}'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              );
            }),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to sign out from Shop Radar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBusinessOwnerCard(BuildContext context, UserModel? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
              : [AppColors.primary, const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Owner Panel 🏪',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      user?.hasBusinessAccount == true
                          ? '${user?.businessCount ?? 1} Registered Business(es)'
                          : 'Manage Shop, Cart, Stall or Service',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'OWNER',
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/owner-dashboard'),
                  icon: const Icon(Icons.dashboard_outlined, size: 16),
                  label: const Text('Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add-product'),
                  icon: const Icon(Icons.add_box_outlined, size: 16),
                  label: const Text('+ Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPartnerCard(BuildContext context, UserModel? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Partner Panel 🛵',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Earn money delivering local orders',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FLEET',
                  style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/delivery-partner'),
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: const Text('Open Delivery Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
