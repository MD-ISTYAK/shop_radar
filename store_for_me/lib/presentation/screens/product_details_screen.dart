import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/common_widgets.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;

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

    if (productState.isLoading || product == null) {
      return const Scaffold(body: LoadingIndicator());
    }

    final isService = product.isService;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel / Header
                  Stack(
                    children: [
                      SizedBox(
                        height: 350,
                        child: product.images.isNotEmpty
                            ? PageView.builder(
                                itemCount: product.images.length,
                                itemBuilder: (context, index) {
                                  return CachedNetworkImage(
                                    imageUrl: AppConstants.getImageUrl(product.images[index]),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorWidget: (context, url, error) => _buildImagePlaceholder(isService),
                                  );
                                },
                              )
                            : _buildImagePlaceholder(isService),
                      ),
                      // Back Button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black38,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      // Service / Product Badge Tag
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isService ? Colors.amber.shade800 : AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isService ? 'SERVICE BOOKING' : 'PRODUCT FOR SALE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Item Info
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Price / Rate
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${product.discountedPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            if (isService) ...[
                              const SizedBox(width: 6),
                              Text(
                                '/ ${product.serviceDuration}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 10),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Service / Product Tag Info
                        if (isService) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_outlined, color: Colors.amber),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verified Service • ${product.bookingType.toUpperCase()} Mode',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Fulfillment is verified via OTP upon service completion.',
                                        style: TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: product.inStock
                                  ? AppColors.success.withAlpha(26)
                                  : AppColors.error.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.inStock
                                  ? 'In Stock (${product.stock} items available)'
                                  : 'Out of Stock',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: product.inStock ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Description
                        Text(isService ? 'Service Overview' : 'Description',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          product.description.isNotEmpty
                              ? product.description
                              : 'No description provided.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // Quantity Selector (For Products Only)
                        if (!isService && product.inStock) ...[
                          Text('Quantity', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _QuantityButton(
                                icon: Icons.remove,
                                onTap: () {
                                  if (_quantity > 1) setState(() => _quantity--);
                                },
                              ),
                              Container(
                                width: 56,
                                alignment: Alignment.center,
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                onTap: () {
                                  if (_quantity < product.stock) setState(() => _quantity++);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar (Buy Now vs Book Service)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isService ? 'Service Rate' : 'Total Amount',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '₹${(product.discountedPrice * _quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: isService
                      ? CustomButton(
                          text: 'Book Service',
                          icon: Icons.calendar_today,
                          onPressed: () => _showBookingSlotSheet(context, product),
                        )
                      : CustomButton(
                          text: 'Add to Cart',
                          icon: Icons.shopping_cart,
                          onPressed: () async {
                            final added =
                                await ref.read(cartProvider.notifier).addToCart(
                                      product.id,
                                      quantity: _quantity,
                                    );
                            if (added && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('✅ Added to cart!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  action: SnackBarAction(
                                    label: 'View Cart',
                                    textColor: Colors.white,
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/cart'),
                                  ),
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

  void _showBookingSlotSheet(BuildContext context, dynamic product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Schedule Service Slot',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.schedule, color: AppColors.primary),
                title: Text('Duration: ${product.serviceDuration}'),
                subtitle: const Text('Vendor will arrive/confirm at scheduled time.'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final added = await ref
                        .read(cartProvider.notifier)
                        .addToCart(product.id, quantity: 1);
                    if (added && context.mounted) {
                      Navigator.pushNamed(context, '/cart');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Proceed to Confirm Booking'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(bool isService) {
    return Container(
      width: double.infinity,
      height: 350,
      color: AppColors.primaryLight.withAlpha(50),
      child: Icon(
        isService ? Icons.home_repair_service : Icons.shopping_bag,
        size: 80,
        color: AppColors.primary,
      ),
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
