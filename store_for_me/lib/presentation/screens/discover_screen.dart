import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/shop_provider.dart';
import '../widgets/premium_widgets.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(shopProvider.notifier).fetchNearbyShops());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // === PREMIUM SEARCH HEADER ===
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumTextField(
                    controller: _searchController,
                    hintText: 'Search shops, categories...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (v) => ref.read(shopProvider.notifier).setSearchQuery(v),
                  ),
                ],
              ),
            ),

            // === TABS ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Explore'),
                    Tab(text: 'Nearby Map'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExploreView(shopState),
                  _buildMapView(shopState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreView(dynamic shopState) {
    return RefreshIndicator(
      onRefresh: () => ref.read(shopProvider.notifier).fetchNearbyShops(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Categories Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/product-listing', arguments: 'All'),
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Categories Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = AppConstants.shopCategories[index + 1]; // Skip 'All'
                final iconCode = AppConstants.categoryIcons[cat] ?? 0xe148;
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/product-listing', arguments: cat),
                  child: _buildCategoryCard(cat, IconData(iconCode, fontFamily: 'MaterialIcons')),
                );
              },
              childCount: 6,
            ),
          ),
        ),

        // Recommended Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
            child: Text(
              'Recommended for you',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        // Shop Grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (shopState.shops.isEmpty) return const SizedBox.shrink();
                final shop = shopState.shops[index % shopState.shops.length];
                return _buildShopGridCard(shop);
              },
              childCount: shopState.shops.length,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCategoryCard(String title, IconData icon) {
    return PremiumGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildShopGridCard(dynamic shop) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(shop.logo),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (shop.isVerified)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: AppColors.primary, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            shop.shopName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                shop.rating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${shop.category}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildMapView(dynamic shopState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_rounded, size: 64, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Map View Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore shops on a visual map grid.',
            style: GoogleFonts.inter(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}






