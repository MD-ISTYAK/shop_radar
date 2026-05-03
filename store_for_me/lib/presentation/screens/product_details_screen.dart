import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/common_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/premium_widgets.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productProvider.notifier).fetchProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final product = productState.selectedProduct;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (productState.isLoading || product == null) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // === PREMIUM IMAGE CAROUSEL ===
                SliverAppBar(
                  expandedHeight: 400,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        product.images.isNotEmpty
                            ? PageView.builder(
                                itemCount: product.images.length,
                                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                                itemBuilder: (context, index) {
                                  return CachedNetworkImage(
                                    imageUrl: AppConstants.getImageUrl(product.images[index]),
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: isDark ? AppColors.darkCard : AppColors.background),
                                    errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                                  );
                                },
                              )
                            : _buildImagePlaceholder(),
                        
                        // Gradient Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.1)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // Indicators
                        if (product.images.length > 1)
                          Positioned(
                            bottom: 24,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product.images.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentImageIndex == i ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == i ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    if (product.hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 10)],
                            ),
                            child: Text(
                              '-${product.discount.toInt()}% OFF',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // === PRODUCT CONTENT ===
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.share_rounded, color: AppColors.textLight, size: 24),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Text(
                              '₹${product.discountedPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: AppColors.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.5',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text('About this product', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text(
                          product.description.isNotEmpty ? product.description : 'No description available for this product.',
                          style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
                        ),
                        const SizedBox(height: 32),

                        // Quantity selector
                        if (product.inStock) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Select Quantity', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    _QuantityButton(
                                      icon: Icons.remove_rounded,
                                      onTap: () {
                                        if (_quantity > 1) setState(() => _quantity--);
                                      },
                                    ),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text('$_quantity', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                                    ),
                                    _QuantityButton(
                                      icon: Icons.add_rounded,
                                      onTap: () {
                                        if (_quantity < product.stock) setState(() => _quantity++);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 100), // Bottom padding for content
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === BOTTOM ACTION BAR ===
          if (product.inStock)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Final Price', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                        Text(
                          '₹${(product.discountedPrice * _quantity).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: PremiumButton(
                      text: 'Add to Cart',
                      icon: Icons.shopping_bag_rounded,
                      onPressed: () async {
                        final added = await ref.read(cartProvider.notifier).addToCart(product.id, quantity: _quantity);
                        if (added && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $_quantity to your cart'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 350,
      color: AppColors.primaryLight.withAlpha(51),
      child: const Icon(Icons.shopping_bag, size: 80, color: AppColors.primary),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}










