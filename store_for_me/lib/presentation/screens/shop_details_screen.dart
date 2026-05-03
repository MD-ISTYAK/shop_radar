import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../widgets/premium_widgets.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (shopState.isLoading || shop == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === PREMIUM BANNER ===
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: shop.banner.isNotEmpty ? AppConstants.getImageUrl(shop.banner) : 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(shop.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                shop.statusLabel.toUpperCase(),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (shop.isVerified)
                              const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shop.shopName,
                          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${shop.rating.toStringAsFixed(1)} (${shop.totalRatings} Reviews)',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === ACTION BUTTONS ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  _buildQuickAction(Icons.phone_rounded, 'Call', AppColors.success, () => _launchPhone(shop.phone)),
                  const SizedBox(width: 12),
                  if (shop.hasWhatsApp)
                    _buildQuickAction(Icons.chat_rounded, 'WhatsApp', const Color(0xFF25D366), () => _launchUrl(shop.whatsappLink)),
                  if (shop.hasWhatsApp) const SizedBox(width: 12),
                  _buildQuickAction(Icons.location_on_rounded, 'Check-In', AppColors.primary, () => _showCheckInDialog()),
                ],
              ),
            ),
          ),

          // === SHOP INFO ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: PremiumGlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.map_rounded, shop.address),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.access_time_filled_rounded, shop.is24x7 ? 'Open 24/7' : '${shop.openingTime} - ${shop.closingTime}'),
                    if (shop.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'About Shop',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shop.description,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _FollowChatButtons(shopId: widget.shopId),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            ),
          ),

          // === PRODUCTS SECTION ===
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Premium Collection',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${productState.products.length} Items',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          if (productState.isLoading)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())))
          else if (productState.products.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No products available')))
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = productState.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.pushNamed(context, '/product-details', arguments: product.id),
                    ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
                  },
                  childCount: productState.products.length,
                ),
              ),
            ),

          // === REVIEWS SECTION ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Reviews',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        onPressed: _showWriteReviewDialog,
                        icon: const Icon(Icons.add_comment_rounded, color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (reviewState.reviews.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No reviews yet.'))
                  else
                    ...reviewState.reviews.take(3).map((r) => _buildReviewCard(r, isDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(dynamic r, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PremiumAvatar(imageUrl: null, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.userName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                    Row(
                      children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return AppColors.success;
      case 'busy': return AppColors.warning;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Check In', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        content: const Text('Check in at this shop to earn 5 loyalty points! 🎉'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          PremiumButton(
            text: 'Check In',
            onPressed: () async {
              final result = await ref.read(checkInProvider.notifier).checkIn(widget.shopId);
              if (mounted) Navigator.pop(ctx);
              if (result && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Checked in! +5 points')));
              }
            },
            width: 100,
            height: 40,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Write Review', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => selectedRating = i + 1),
                  child: Icon(i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            PremiumButton(
              text: 'Post',
              onPressed: () async {
                final result = await ref.read(reviewProvider.notifier).createReview(widget.shopId, selectedRating, textCtrl.text);
                if (mounted) Navigator.pop(ctx);
                if (result && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⭐ Review posted!')));
                }
              },
              width: 80,
              height: 40,
            ),
          ],
        );
      }),
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
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: _isFollowing ? 'Following' : 'Follow Shop',
            onPressed: _isLoadingFollow ? () {} : _toggleFollow,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _startChat,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }
}
