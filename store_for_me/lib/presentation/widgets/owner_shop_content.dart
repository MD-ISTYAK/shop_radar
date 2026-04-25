import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../providers/shop_provider.dart';
import '../providers/product_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OwnerShopContent extends ConsumerWidget {
  final ScrollController scrollController;
  const OwnerShopContent({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final shop = shopState.ownerShop;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop Management', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 8),
          Text('Manage your products and shop profile', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          const SizedBox(height: 24),
          
          _ActionTile(
            icon: Icons.add_box_rounded,
            title: 'Add New Product',
            subtitle: 'List a new item in your catalog',
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
            subtitle: 'Edit prices, stock and details',
            color: AppColors.info,
            onTap: () async {
              await Navigator.pushNamed(context, '/manage-products');
              ref.read(productProvider.notifier).fetchOwnerProducts();
              ref.read(shopProvider.notifier).fetchOwnerShop();
            },
          ),
          _ActionTile(
            icon: Icons.edit_rounded,
            title: 'Update Shop Profile',
            subtitle: 'Update address, timing and logo',
            color: AppColors.secondary,
            onTap: () => Navigator.pushNamed(context, '/add-shop', arguments: shop),
          ),
          _ActionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Order Scanner',
            subtitle: 'Scan customer QR to verify',
            color: AppColors.accent,
            onTap: () => Navigator.pushNamed(context, '/order-scanner'),
          ),
          SizedBox(height: 24),
          
          Text('Current Status', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop?.isOpen ?? false ? 'Your Shop is Open' : 'Your Shop is Closed',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop?.isOpen ?? false ? 'Customers can place orders' : 'Visibility is limited',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                Switch(
                  value: shop?.isOpen ?? false,
                  onChanged: (val) => ref.read(shopProvider.notifier).toggleShopStatus(),
                  activeColor: AppColors.accent,
                ),
              ],
            ),
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









