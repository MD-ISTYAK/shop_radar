import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shop_model.dart';

class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback onTap;

  const ShopCard({super.key, required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Shop Image with status indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 110,
                    height: 120,
                    child: shop.logo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConstants.getImageUrl(shop.logo),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.shimmerBase,
                              child: const Icon(Icons.store, size: 40, color: Colors.white),
                            ),
                            errorWidget: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                // Status dot
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: _getStatusColor().withAlpha(80), blurRadius: 6)],
                    ),
                  ),
                ),
                // 24x7 badge
                if (shop.is24x7)
                  Positioned(
                    bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('24×7', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
                // Trending badge
                if (shop.isTrending)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.local_fire_department, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),

            // Shop Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Verified
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.shopName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (shop.isVerified)
                          const Icon(Icons.verified, color: AppColors.primary, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(shop.category, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),

                    // Rating, Distance, Crowd
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        Text(' (${shop.totalRatings})', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        if (shop.distanceFormatted != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 13, color: AppColors.textLight),
                          const SizedBox(width: 2),
                          Text(shop.distanceFormatted!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Status & Crowd
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            shop.statusLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _getStatusColor()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Crowd indicator
                        Text(shop.crowdEmoji, style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(
                          shop.crowdLabel,
                          style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500),
                        ),
                        // Followers
                        if (shop.followers > 0) ...[
                          const Spacer(),
                          Icon(Icons.people_outline, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 2),
                          Text('${shop.followers}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                        ],
                      ],
                    ),

                    // Features chips
                    if (shop.features.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: shop.features.take(3).map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _featureLabel(f),
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (shop.status) {
      case 'open': return AppColors.success;
      case 'busy': return AppColors.warning;
      case 'closed': return AppColors.textLight;
      case 'temporarily_closed': return AppColors.error;
      default: return AppColors.textLight;
    }
  }

  String _featureLabel(String feature) {
    final labels = {
      'wifi': '📶 WiFi',
      'parking': '🅿️ Parking',
      'ac': '❄️ AC',
      'card_payment': '💳 Card',
      'upi': '📱 UPI',
      'home_delivery': '🚚 Delivery',
      'dine_in': '🍽️ Dine-in',
      'takeaway': '📦 Takeaway',
      'wheelchair_access': '♿ Accessible',
    };
    return labels[feature] ?? feature;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight.withAlpha(51),
      child: const Icon(Icons.store, size: 40, color: AppColors.primary),
    );
  }
}
