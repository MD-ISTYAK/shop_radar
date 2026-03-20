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
  const OwnerDashboardScreen({super.key});

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: shopState.isLoading
            ? const LoadingIndicator()
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(shopProvider.notifier).fetchOwnerShop();
                  await ref.read(productProvider.notifier).fetchOwnerProducts();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                const SizedBox(height: 4),
                                Text(
                                  'Welcome, ${authState.user?.name ?? 'Owner'}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                await ref.read(authProvider.notifier).logout();
                                if (mounted) Navigator.pushReplacementNamed(context, '/login');
                              },
                              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                              tooltip: 'Logout',
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
                                          imageUrl: '${AppConstants.uploadsUrl}${shop.logo}',
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
                                          const SizedBox(width: 6),
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
                        const SizedBox(height: 20),

                        // Analytics
                        Row(
                          children: [
                            Expanded(
                              child: _AnalyticsCard(
                                icon: Icons.inventory_2_rounded,
                                label: 'Products',
                                value: '${analytics?['totalProducts'] ?? 0}',
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AnalyticsCard(
                                icon: Icons.shopping_bag_rounded,
                                label: 'Orders',
                                value: '${analytics?['totalOrders'] ?? 0}',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AnalyticsCard(
                                icon: Icons.currency_rupee_rounded,
                                label: 'Earnings',
                                value: '₹${analytics?['totalEarnings'] ?? 0}',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Quick actions
                        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _ActionTile(
                          icon: Icons.add_box_rounded,
                          title: 'Add Product',
                          subtitle: 'Add a new product to your shop',
                          color: AppColors.primary,
                          onTap: () async {
                            await Navigator.pushNamed(context, '/add-product');
                            ref.read(productProvider.notifier).fetchOwnerProducts();
                            ref.read(shopProvider.notifier).fetchOwnerShop();
                          },
                        ),
                        _ActionTile(
                          icon: Icons.inventory_rounded,
                          title: 'Manage Products',
                          subtitle: 'Edit or remove products',
                          color: AppColors.info,
                          onTap: () async {
                            await Navigator.pushNamed(context, '/manage-products');
                            ref.read(productProvider.notifier).fetchOwnerProducts();
                            ref.read(shopProvider.notifier).fetchOwnerShop();
                          },
                        ),
                        _ActionTile(
                          icon: Icons.edit_rounded,
                          title: 'Update Shop',
                          subtitle: 'Update your shop details',
                          color: AppColors.secondary,
                          onTap: () => Navigator.pushNamed(context, '/add-shop', arguments: shop),
                        ),
                        const SizedBox(height: 24),

                        // Social Actions
                        Text('Social Media', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _ActionTile(
                          icon: Icons.post_add_rounded,
                          title: 'Create Post',
                          subtitle: 'Share updates, offers & photos with followers',
                          color: AppColors.accent,
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, '/create-post');
                            if (result == true) {
                              ref.read(shopProvider.notifier).fetchOwnerShop();
                            }
                          },
                        ),
                        _ActionTile(
                          icon: Icons.auto_stories_rounded,
                          title: 'Create Story',
                          subtitle: 'Upload a 24-hour disappearing story',
                          color: AppColors.warning,
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, '/create-story');
                            if (result == true) {
                              ref.read(shopProvider.notifier).fetchOwnerShop();
                            }
                          },
                        ),
                        _ActionTile(
                          icon: Icons.settings_suggest_rounded,
                          title: 'Manage Content',
                          subtitle: 'Edit, hide or delete your posts and stories',
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, '/shop-management'),
                        ),
                        _ActionTile(
                          icon: Icons.chat_rounded,
                          title: 'Messages',
                          subtitle: 'Chat with your customers',
                          color: AppColors.success,
                          onTap: () => Navigator.pushNamed(context, '/chat-list'),
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
                                child: const Text('View All'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

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
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider.withAlpha(128)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textLight),
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
                                  icon: const Icon(Icons.add, size: 18),
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
                                color: AppColors.card,
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
                                                imageUrl: '${AppConstants.uploadsUrl}${product.images.first}',
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Container(color: AppColors.shimmerBase),
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
                                    const SizedBox(width: 12),
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
                                                    color: AppColors.textLight,
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
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
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
