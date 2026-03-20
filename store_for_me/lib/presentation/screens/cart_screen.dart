import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/common_widgets.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cart = cartState.cart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartState.isLoading
          ? const LoadingIndicator()
          : (cart == null || cart.items.isEmpty)
              ? const EmptyStateWidget(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                  subtitle: 'Browse shops and add products to cart',
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          final product = item.product;
                          if (product == null) return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                      width: 80,
                                      height: 80,
                                      child: product.images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: '${AppConstants.uploadsUrl}${product.images.first}',
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                                              errorWidget: (_, __, ___) => Container(
                                                color: AppColors.primaryLight.withAlpha(51),
                                                child: const Icon(Icons.shopping_bag, color: AppColors.primary),
                                              ),
                                            )
                                          : Container(
                                              color: AppColors.primaryLight.withAlpha(51),
                                              child: const Icon(Icons.shopping_bag, color: AppColors.primary),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Product info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '₹${product.discountedPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Quantity controls
                                        Row(
                                          children: [
                                            _CartQuantityButton(
                                              icon: Icons.remove,
                                              onTap: () {
                                                if (item.quantity > 1) {
                                                  ref.read(cartProvider.notifier).updateQuantity(
                                                        item.productId,
                                                        item.quantity - 1,
                                                      );
                                                }
                                              },
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            _CartQuantityButton(
                                              icon: Icons.add,
                                              onTap: () {
                                                ref.read(cartProvider.notifier).updateQuantity(
                                                      item.productId,
                                                      item.quantity + 1,
                                                    );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Delete button
                                  IconButton(
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).removeFromCart(item.productId);
                                    },
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Checkout section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, -2))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
                              Text(
                                '₹${cartState.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery', style: Theme.of(context).textTheme.bodyMedium),
                              const Text(
                                'Free',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: Theme.of(context).textTheme.titleLarge),
                              Text(
                                '₹${cartState.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Checkout',
                            icon: Icons.payment,
                            isLoading: cartState.isLoading,
                            onPressed: () async {
                              final success = await ref.read(cartProvider.notifier).checkout();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Order placed successfully! 🎉'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CartQuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CartQuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}
