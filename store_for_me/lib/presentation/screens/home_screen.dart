import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/deal_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/shop_card.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopProvider.notifier).fetchNearbyShops();
      ref.read(dealProvider.notifier).fetchTrendingDeals();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final authState = ref.watch(authProvider);
    final dealState = ref.watch(dealProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(shopProvider.notifier).fetchNearbyShops();
            await ref.read(dealProvider.notifier).fetchTrendingDeals();
          },
          child: CustomScrollView(
            slivers: [
              // === HEADER ===
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, ${authState.user?.name.split(' ').first ?? 'there'}! 👋',
                                  style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                                  ),
                                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                                SizedBox(height: 4),
                                Text(
                                  'Discover shops around you',
                                  style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(200)),
                                ),
                              ],
                            ),
                          ),
                          // Notification bell
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                              ),
                              if (ref.watch(notificationProvider).unreadCount > 0)
                                Positioned(
                                  right: 6, top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: Text(
                                      '${ref.watch(notificationProvider).unreadCount}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Cart icon
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/cart'),
                            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 26),
                            tooltip: 'Cart',
                          ),
                          // Emergency SOS
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/emergency'),
                            icon: const Icon(Icons.emergency, color: Colors.redAccent, size: 26),
                            tooltip: 'Emergency SOS',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => ref.read(shopProvider.notifier).setSearchQuery(v),
                          decoration: InputDecoration(
                            hintText: 'Search shops, products...',
                            prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(shopProvider.notifier).setSearchQuery('');
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.mic, color: AppColors.primary),
                                  onPressed: () {
                                    // TODO: Voice search
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),

              // === QUICK ACTIONS ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(Icons.map_rounded, 'Map View', AppColors.info, () => Navigator.pushNamed(context, '/discover')),
                      _buildQuickAction(Icons.local_offer, 'Deals', AppColors.success, () => Navigator.pushNamed(context, '/deals')),
                      _buildQuickAction(Icons.question_answer, 'Ask', AppColors.warning, () => Navigator.pushNamed(context, '/community')),
                      _buildQuickAction(Icons.leaderboard, 'Badges', AppColors.primary, () => Navigator.pushNamed(context, '/badges')),
                    ],
                  ).animate().fadeIn(duration: 600.ms),
                ),
              ),

              // === CATEGORIES ===
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: AppConstants.shopCategories.length,
                    itemBuilder: (context, index) {
                      final category = AppConstants.shopCategories[index];
                      final isSelected = shopState.selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          backgroundColor: Theme.of(context).cardColor,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                          ),
                          onSelected: (_) => ref.read(shopProvider.notifier).setCategory(category),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // === TRENDING DEALS BANNER ===
              if (dealState.trendingDeals.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 22),
                            const SizedBox(width: 6),
                            const Text('Trending Deals', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/deals'),
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: dealState.trendingDeals.length.clamp(0, 5),
                          itemBuilder: (context, index) {
                            final deal = dealState.trendingDeals[index];
                            return Container(
                              width: 260,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary.withAlpha(220), AppColors.accent.withAlpha(200)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deal.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(deal.shopName, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                        child: Text(
                                          '${deal.discountPercent}% OFF',
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '₹${deal.dealPrice.toInt()}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (100 * index).ms);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // === NEARBY SHOPS ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Text('Nearby Shops', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.sort, size: 18),
                        label: const Text('Sort', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              if (shopState.isLoading)
                const SliverFillRemaining(
                  child: LoadingIndicator(message: 'Finding nearby shops...'),
                )
              else if (shopState.shops.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.store_outlined,
                    title: 'No shops found',
                    subtitle: 'Try a different search or category',
                    buttonText: 'Refresh',
                    onButtonPressed: () => ref.read(shopProvider.notifier).fetchNearbyShops(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shop = shopState.shops[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ShopCard(
                          shop: shop,
                          onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
                        ),
                      ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.05);
                    },
                    childCount: shopState.shops.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: (color ?? Colors.transparent).withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}









