import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../providers/shop_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/social_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/common_widgets.dart';

class ShopDetailsScreen extends ConsumerStatefulWidget {
  final String shopId;
  const ShopDetailsScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends ConsumerState<ShopDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopProvider.notifier).fetchShopById(widget.shopId);
      ref.read(productProvider.notifier).fetchProductsByShop(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final productState = ref.watch(productProvider);
    final shop = shopState.selectedShop;

    if (shopState.isLoading || shop == null) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Banner
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: shop.banner.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: AppConstants.getImageUrl(shop.banner),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.primaryLight.withAlpha(51)),
                      errorWidget: (_, __, ___) => _buildBannerPlaceholder(),
                    )
                  : _buildBannerPlaceholder(),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Shop info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.shopName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: shop.isOpen ? AppColors.success.withAlpha(26) : AppColors.error.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          shop.isOpen ? '● Open' : '● Closed',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: shop.isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${shop.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('(${shop.totalRatings} reviews)',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(shop.category,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Info rows
                  _InfoRow(icon: Icons.location_on_outlined, text: shop.address),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.access_time,
                    text: '${shop.openingTime} - ${shop.closingTime}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.phone_outlined, text: shop.phone),
                  if (shop.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.info_outline, text: shop.description),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Follow & Chat buttons
                  _FollowChatButtons(shopId: widget.shopId),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Products header
                  Text('Products', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${productState.products.length} items',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Products grid
          productState.isLoading
              ? const SliverFillRemaining(child: LoadingIndicator())
              : productState.products.isEmpty
                  ? const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products yet',
                        subtitle: 'This shop hasn\'t added any products',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = productState.products[index];
                            return ProductCard(
                              product: product,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/product-details',
                                arguments: product.id,
                              ),
                              onAddToCart: () async {
                                final added = await ref.read(cartProvider.notifier).addToCart(product.id);
                                if (added && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Added to cart'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                          childCount: productState.products.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: AppColors.primaryLight.withAlpha(51),
      child: const Icon(Icons.storefront, size: 80, color: AppColors.primary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _FollowChatButtons extends ConsumerStatefulWidget {
  final String shopId;
  const _FollowChatButtons({required this.shopId});

  @override
  ConsumerState<_FollowChatButtons> createState() => _FollowChatButtonsState();
}

class _FollowChatButtonsState extends ConsumerState<_FollowChatButtons> {
  bool _isFollowing = false;
  bool _isLoadingFollow = true;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final apiService = ApiService();
      final checkResp = await apiService.checkFollow(widget.shopId);
      final countResp = await apiService.getFollowersCount(widget.shopId);
      if (mounted) {
        setState(() {
          _isFollowing = checkResp.data['data']?['isFollowing'] ?? false;
          _followersCount = countResp.data['data']?['count'] ?? 0;
          _isLoadingFollow = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFollow = false);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoadingFollow = true);
    final success = await ref.read(socialProvider.notifier).toggleFollow(widget.shopId);
    if (success) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followersCount += _isFollowing ? 1 : -1;
        _isLoadingFollow = false;
      });
    } else {
      setState(() => _isLoadingFollow = false);
    }
  }

  Future<void> _startChat() async {
    final data = await ref.read(chatProvider.notifier).startConversation(widget.shopId);
    if (data != null && mounted) {
      Navigator.pushNamed(context, '/chat', arguments: {
        'conversationId': data['conversationId']?.toString() ?? '',
        'receiverId': data['otherUser']?['_id']?.toString() ?? '',
        'shopId': data['shop']?['_id']?.toString() ?? '',
        'title': data['shop']?['shopName']?.toString() ?? 'Chat',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == 'owner';

    return Column(
      children: [
        Row(
          children: [
            // Followers count
            Column(
              children: [
                Text('$_followersCount', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                Text('Followers', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 24),

            // Follow button (hidden for owner viewing own shop)
            if (!isOwner)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoadingFollow ? null : _toggleFollow,
                  icon: Icon(_isFollowing ? Icons.favorite : Icons.favorite_border, size: 18),
                  label: Text(_isFollowing ? 'Following' : 'Follow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? AppColors.card : AppColors.primary,
                    foregroundColor: _isFollowing ? AppColors.primary : Colors.white,
                    side: _isFollowing ? const BorderSide(color: AppColors.primary) : null,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            if (!isOwner) const SizedBox(width: 10),

            // Chat button
            if (!isOwner)
              OutlinedButton.icon(
                onPressed: _startChat,
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

