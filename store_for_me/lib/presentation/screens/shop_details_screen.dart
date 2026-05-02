import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../providers/shop_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/social_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../providers/review_provider.dart';
import '../providers/deal_provider.dart';
import '../providers/check_in_provider.dart';
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
      ref.read(reviewProvider.notifier).fetchShopReviews(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final productState = ref.watch(productProvider);
    final reviewState = ref.watch(reviewProvider);
    final shop = shopState.selectedShop;

    if (shopState.isLoading || shop == null) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(shopProvider.notifier).fetchShopById(widget.shopId);
          await ref.read(productProvider.notifier).fetchProductsByShop(widget.shopId);
          await ref.read(reviewProvider.notifier).fetchShopReviews(widget.shopId);
        },
        child: CustomScrollView(
        slivers: [
          // === BANNER ===
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  shop.banner.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: AppConstants.getImageUrl(shop.banner),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.primaryLight.withAlpha(51)),
                          errorWidget: (_, __, ___) => _buildBannerPlaceholder(),
                        )
                      : _buildBannerPlaceholder(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withAlpha(160)],
                      ),
                    ),
                  ),
                  // Bottom badges
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Row(
                      children: [
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(shop.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(shop.statusLabel,
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(width: 8),
                        // Crowd
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${shop.crowdEmoji} ${shop.crowdLabel}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                        const Spacer(),
                        if (shop.is24x7)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('24×7', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),

          // === SHOP INFO ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(shop.shopName, style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      if (shop.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: AppColors.primary, size: 16),
                              SizedBox(width: 4),
                              Text('Verified', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating & Category
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${shop.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('(${shop.totalRatings} reviews)', style: Theme.of(context).textTheme.bodySmall),
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

                  // === ACTION BUTTONS ROW ===
                  Row(
                    children: [
                      _buildActionButton(Icons.phone, 'Call', AppColors.success, () => _launchPhone(shop.phone)),
                      const SizedBox(width: 10),
                      if (shop.hasWhatsApp)
                        _buildActionButton(Icons.chat, 'WhatsApp', const Color(0xFF25D366), () => _launchUrl(shop.whatsappLink)),
                      if (shop.hasWhatsApp) const SizedBox(width: 10),
                      _buildActionButton(Icons.location_on, 'Check-In', AppColors.primary, () => _showCheckInDialog()),
                      const SizedBox(width: 10),
                      if (shop.queueEnabled)
                        _buildActionButton(Icons.confirmation_number, 'Queue', AppColors.warning, () {
                          Navigator.pushNamed(context, '/queue', arguments: {'shopId': shop.id, 'shopName': shop.shopName});
                        }),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Info rows
                  _InfoRow(icon: Icons.location_on_outlined, text: shop.address),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.access_time,
                    text: shop.is24x7 ? 'Open 24 hours, 7 days a week' : '${shop.openingTime} - ${shop.closingTime}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.phone_outlined, text: shop.phone),
                  if (shop.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.info_outline, text: shop.description),
                  ],
                  if (shop.operatingDays.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.calendar_today, text: 'Open: ${shop.operatingDays.join(', ')}'),
                  ],

                  // Features
                  if (shop.features.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Amenities', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: shop.features.map((f) {
                        final labels = {
                          'wifi': '📶 WiFi', 'parking': '🅿️ Parking', 'ac': '❄️ AC',
                          'card_payment': '💳 Card', 'upi': '📱 UPI', 'home_delivery': '🚚 Delivery',
                          'dine_in': '🍽️ Dine-in', 'takeaway': '📦 Takeaway', 'wheelchair_access': '♿ Accessible',
                        };
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withAlpha(40)),
                          ),
                          child: Text(labels[f] ?? f, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ],

                  SizedBox(height: 20),
                  const Divider(),
                  SizedBox(height: 12),

                  // Follow & Chat buttons
                  _FollowChatButtons(shopId: widget.shopId),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // === REVIEWS SECTION ===
                  Row(
                    children: [
                      const Text('Reviews', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showWriteReviewDialog(),
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Write Review'),
                      ),
                    ],
                  ),
                  if (reviewState.reviews.isNotEmpty)
                    ...reviewState.reviews.take(3).map((review) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary.withAlpha(25),
                                  child: Text(review.userName.isNotEmpty ? review.userName[0] : '?',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Row(
                                        children: List.generate(5, (i) => Icon(
                                          i < review.rating ? Icons.star : Icons.star_border,
                                          color: Colors.amber, size: 14)),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => ref.read(reviewProvider.notifier).toggleUpvote(review.id, widget.shopId),
                                  child: Row(
                                    children: [
                                      Icon(Icons.thumb_up_outlined, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                                      const SizedBox(width: 4),
                                      Text('${review.upvoteCount}', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (review.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(review.text, style: const TextStyle(fontSize: 13)),
                            ],
                            if (review.ownerReply != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withAlpha(25)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.store, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(review.ownerReply!.text, style: const TextStyle(fontSize: 12))),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  if (reviewState.reviews.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                    ),

                  SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Products header
                  Row(
                    children: [
                      Text('Products', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Text('${productState.products.length} items', style: Theme.of(context).textTheme.bodySmall),
                    ],
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
                              onTap: () => Navigator.pushNamed(context, '/product-details', arguments: product.id),
                              onAddToCart: () async {
                                final added = await ref.read(cartProvider.notifier).addToCart(product.id);
                                if (added && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('✅ Added to cart'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      action: SnackBarAction(
                                        label: 'View Cart',
                                        textColor: Colors.white,
                                        onPressed: () => Navigator.pushNamed(context, '/cart'),
                                      ),
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
    ),
  );
}

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: (color ?? Colors.transparent).withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (color ?? Colors.transparent).withAlpha(50)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return AppColors.success;
      case 'busy': return AppColors.warning;
      case 'closed': return AppColors.textLight;
      case 'temporarily_closed': return AppColors.error;
      default: return AppColors.textLight;
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showCheckInDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Check In'),
        content: const Text('Check in at this shop to earn 5 loyalty points! 🎉'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(checkInProvider.notifier).checkIn(widget.shopId);
              if (mounted) Navigator.pop(ctx);
              if (result && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✅ Checked in! +5 points'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog() {
    final textCtrl = TextEditingController();
    int selectedRating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber, size: 32,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Share your experience...'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final result = await ref.read(reviewProvider.notifier).createReview(widget.shopId, selectedRating, textCtrl.text);
                if (mounted) Navigator.pop(ctx);
                if (result && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⭐ Review posted! Thanks!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Post Review'),
            ),
          ],
        );
      }),
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
        Icon(icon, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
        SizedBox(width: 10),
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
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final success = await ref.read(socialProvider.notifier).toggleFollow(widget.shopId, currentUserId);
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
        'otherUser': ChatUserModel.fromJson(data['otherUser'] ?? {}),
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
            Column(
              children: [
                Text('$_followersCount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                Text('Followers', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 24),
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







