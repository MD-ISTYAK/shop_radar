import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/common_widgets.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: shopState.isLoading
            ? const LoadingIndicator()
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(shopProvider.notifier).fetchOwnerShop();
                  await ref.read(productProvider.notifier).fetchOwnerProducts();
                },
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dashboard',
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Welcome, ${authState.user?.name ?? 'Owner'}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (shop == null) ...[
                        // No shop registered CTA
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(60),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.store_rounded, size: 48, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Register Your Shop',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start selling by registering your shop',
                                style: TextStyle(color: Colors.white.withAlpha(204)),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/add-shop'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                ),
                                child: const Text('Register Shop'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Shop status card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(50),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Shop logo
                                  if (shop.logo.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(right: 14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withAlpha(60), width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: AppConstants.getImageUrl(shop.logo),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.white.withAlpha(30),
                                            child: const Icon(Icons.store, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop.shopName,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          shop.category,
                                          style: TextStyle(color: Colors.white.withAlpha(204)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Toggle button
                                  GestureDetector(
                                    onTap: () async {
                                      await ref.read(shopProvider.notifier).toggleShopStatus();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(40),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: shop.isOpen ? AppColors.accent : AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            shop.isOpen ? 'Open' : 'Closed',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Analytics Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _AnalyticsCard(
                              icon: Icons.currency_rupee_rounded,
                              label: 'Earnings',
                              value: '₹${analytics?['totalEarnings'] ?? 0}',
                              color: AppColors.success,
                            ),
                            _AnalyticsCard(
                              icon: Icons.local_shipping_rounded,
                              label: 'Delivery',
                              value: '${analytics?['deliveryStats']?['pending'] ?? 0}/${analytics?['deliveryStats']?['total'] ?? 0}',
                              color: AppColors.info,
                            ),
                            _AnalyticsCard(
                              icon: Icons.people_rounded,
                              label: 'Followers',
                              value: '${analytics?['totalFollowers'] ?? 0}',
                              color: AppColors.accent,
                            ),
                            _AnalyticsCard(
                              icon: Icons.location_on_rounded,
                              label: 'Checking',
                              value: '${analytics?['totalCheckIns'] ?? 0}',
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AnalyticsCard(
                          icon: Icons.task_alt_rounded,
                          label: 'Successful Orders Done',
                          value: '${analytics?['successfulOrders'] ?? 0}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),

                        // Your Products section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Your Products', style: Theme.of(context).textTheme.titleLarge),
                            if (productState.ownerProducts.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  await Navigator.pushNamed(context, '/manage-products');
                                  ref.read(productProvider.notifier).fetchOwnerProducts();
                                },
                                child: Text('View All'),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),

                        if (productState.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (productState.ownerProducts.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).dividerColor.withAlpha(128)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                                const SizedBox(height: 12),
                                Text(
                                  'No products yet',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add your first product to start selling',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.pushNamed(context, '/add-product');
                                    ref.read(productProvider.notifier).fetchOwnerProducts();
                                  },
                                  icon: Icon(Icons.add, size: 18),
                                  label: const Text('Add Product'),
                                ),
                              ],
                            ),
                          )
                        else
                          ...productState.ownerProducts.take(6).map((product) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Product image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: product.images.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: AppConstants.getImageUrl(product.images.first),
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Container(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkShimmerBase : AppColors.shimmerBase)),
                                                errorWidget: (_, __, ___) => Container(
                                                  color: AppColors.primaryLight.withAlpha(30),
                                                  child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 24),
                                                ),
                                              )
                                            : Container(
                                                color: AppColors.primaryLight.withAlpha(30),
                                                child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 24),
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                '₹${product.discountedPrice.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (product.hasDiscount) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  '₹${product.price.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                              ],
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: product.inStock
                                                      ? AppColors.success.withAlpha(20)
                                                      : AppColors.error.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  product.inStock ? 'Stock: ${product.stock}' : 'Out',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: product.inStock ? AppColors.success : AppColors.error,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AnalyticsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? Colors.transparent).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
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











