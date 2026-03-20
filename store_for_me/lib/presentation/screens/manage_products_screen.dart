import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';
import '../widgets/common_widgets.dart';

class ManageProductsScreen extends ConsumerStatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  ConsumerState<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends ConsumerState<ManageProductsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productProvider.notifier).fetchOwnerProducts());
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add-product'),
          ),
        ],
      ),
      body: productState.isLoading
          ? const LoadingIndicator()
          : productState.ownerProducts.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products yet',
                  subtitle: 'Add your first product to start selling',
                  buttonText: 'Add Product',
                  onButtonPressed: () => Navigator.pushNamed(context, '/add-product'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productState.ownerProducts.length,
                  itemBuilder: (context, index) {
                    final product = productState.ownerProducts[index];
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
                                width: 70,
                                height: 70,
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

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${product.discountedPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: product.inStock
                                              ? AppColors.success.withAlpha(26)
                                              : AppColors.error.withAlpha(26),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          product.inStock ? 'In Stock (${product.stock})' : 'Out of Stock',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: product.inStock ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ),
                                      if (product.hasDiscount) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withAlpha(26),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '-${product.discount.toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // Edit product
                                    Navigator.pushNamed(context, '/add-product', arguments: product);
                                  },
                                  icon: const Icon(Icons.edit, color: AppColors.info, size: 20),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Delete Product'),
                                        content: Text('Delete "${product.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(productProvider.notifier).deleteProduct(product.id);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-product'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
