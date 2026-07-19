import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/social_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_bubble.dart';
import '../widgets/premium_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(socialProvider.notifier).fetchFeed();
      ref.read(shopProvider.notifier).fetchNearbyShops();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final socialState = ref.watch(socialProvider);
    final shopState = ref.watch(shopProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === PREMIUM BRAND HEADER ===
          SliverAppBar(
            floating: true,
            pinned: false,
            elevation: 0,
            toolbarHeight: 70,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              'Shop Radar',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
            actions: [
              _buildAppBarIcon(Icons.search_rounded, () {}),
              _buildAppBarIcon(Icons.notifications_none_rounded, () => Navigator.pushNamed(context, '/notifications'), 
                count: ref.watch(notificationProvider).unreadCount),
              _buildAppBarIcon(Icons.emergency_outlined, () => Navigator.pushNamed(context, '/emergency'), color: Colors.redAccent),
              const SizedBox(width: 8),
            ],
          ),

          // === FEATURED SHOPS (STORIES) ===
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: shopState.shops.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCreateStoryBubble(authState.user?.avatar);
                      }
                      final shop = shopState.shops[index - 1];
                      return StoryBubble(
                        imageUrl: shop.logo,
                        name: shop.shopName,
                        isVerified: shop.isVerified,
                        onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: AppColors.textLight.withValues(alpha: 0.1), thickness: 1),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          ),

          // === FEED FEED SECTION ===
          if (socialState.isLoading && socialState.feed.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (socialState.feed.isEmpty)
            _buildEmptyFeed()
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = socialState.feed[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: PostCard(post: post),
                    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
                  },
                  childCount: socialState.feed.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, VoidCallback onTap, {int count = 0, Color? color}) {
    return Stack(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color ?? AppColors.textPrimary, size: 26),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCreateStoryBubble(String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              PremiumAvatar(imageUrl: avatarUrl, size: 68),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your Story',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_mosaic_rounded, size: 64, color: AppColors.textLight.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Nothing to see here yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textLight),
          ),
          Text(
            'Follow shops to see their updates',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          PremiumButton(
            text: 'Discover Shops',
            onPressed: () {},
            width: 160,
            height: 44,
          ),
        ],
      ),
    );
  }
}





