import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/premium_widgets.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const OwnerDashboardScreen({super.key, required this.scrollController});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopProvider.notifier).fetchOwnerShop();
      ref.read(productProvider.notifier).fetchOwnerProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final authState = ref.watch(authProvider);
    final productState = ref.watch(productProvider);
    final shop = shopState.ownerShop;
    final analytics = shopState.analytics;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: shopState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(shopProvider.notifier).fetchOwnerShop();
                await ref.read(productProvider.notifier).fetchOwnerProducts();
              },
              child: CustomScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // === DASHBOARD HEADER ===
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Hub',
                            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                          Text(
                            'Manage your shop and growth',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // === SHOP STATUS CARD ===
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: shop == null ? _buildRegisterCTA() : _buildShopStatusCard(shop, isDark),
                    ).animate().fadeIn().slideY(begin: 0.1),
                  ),

                  // === ANALYTICS GRID ===
                  if (shop != null)
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
                            final items = [
                              _AnalyticsItem(Icons.payments_rounded, 'Earnings', '₹${analytics?['totalEarnings'] ?? 0}', AppColors.success),
                              _AnalyticsItem(Icons.local_shipping_rounded, 'Orders', '${analytics?['successfulOrders'] ?? 0}', AppColors.primary),
                              _AnalyticsItem(Icons.group_rounded, 'Followers', '${analytics?['totalFollowers'] ?? 0}', AppColors.accent),
                              _AnalyticsItem(Icons.ads_click_rounded, 'Visits', '${analytics?['totalCheckIns'] ?? 0}', AppColors.warning),
                            ];
                            return _buildAnalyticsCard(items[index], isDark);
                          },
                          childCount: 4,
                        ),
                      ),
                    ),

                  // === PRODUCT MANAGEMENT SECTION ===
                  if (shop != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Inventory',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/manage-products'),
                              child: Text('Manage All', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (productState.ownerProducts.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyInventory())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = productState.ownerProducts[index];
                              return _buildProductListTile(product, isDark);
                            },
                            childCount: productState.ownerProducts.length.clamp(0, 5),
                          ),
                        ),
                      ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildRegisterCTA() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Icon(Icons.storefront_rounded, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text('Register Your Shop', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Join the marketplace and start selling today!', style: GoogleFonts.inter(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          PremiumButton(
            text: 'Get Started',
            onPressed: () => Navigator.pushNamed(context, '/add-shop'),
            backgroundColor: Colors.white,
            textColor: AppColors.primary,
            width: 160,
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusCard(dynamic shop, bool isDark) {
    return PremiumGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          PremiumAvatar(imageUrl: shop.logo, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.shopName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(shop.category, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(shopProvider.notifier).toggleShopStatus(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: shop.isOpen ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (shop.isOpen ? AppColors.success : AppColors.error).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: shop.isOpen ? AppColors.success : AppColors.error, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(shop.isOpen ? 'OPEN' : 'CLOSED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: shop.isOpen ? AppColors.success : AppColors.error)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(_AnalyticsItem item, bool isDark) {
    return PremiumGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const Spacer(),
          Text(item.value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(item.label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProductListTile(dynamic product, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.images.isNotEmpty
                ? CachedNetworkImage(imageUrl: AppConstants.getImageUrl(product.images.first), width: 50, height: 50, fit: BoxFit.cover)
                : Container(width: 50, height: 50, color: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.inventory_2, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1),
                Text('₹${product.discountedPrice}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.inStock ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.inStock ? 'Stock: ${product.stock}' : 'Out of Stock',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: product.inStock ? AppColors.success : AppColors.error),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildEmptyInventory() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.add_shopping_cart_rounded, size: 48, color: AppColors.textLight.withOpacity(0.2)),
        const SizedBox(height: 12),
        Text('No products listed', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textLight)),
        const SizedBox(height: 16),
        PremiumButton(text: 'Add First Product', onPressed: () => Navigator.pushNamed(context, '/add-product'), width: 180, height: 44),
      ],
    );
  }
}

class _AnalyticsItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _AnalyticsItem(this.icon, this.label, this.value, this.color);
}


class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? Colors.transparent).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}











