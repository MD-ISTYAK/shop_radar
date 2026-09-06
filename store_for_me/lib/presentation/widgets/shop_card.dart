import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shop_model.dart';

class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback onTap;

  const ShopCard({super.key, required this.shop, required this.onTap});

  void _openDirections(BuildContext context) async {
    final hasCoords = shop.location != null &&
        (shop.location!.latitude != 0 || shop.location!.longitude != 0);

    final String googleMapsUrl = hasCoords
        ? 'https://www.google.com/maps/dir/?api=1&destination=${shop.location!.latitude},${shop.location!.longitude}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('${shop.shopName}, ${shop.address}')}';

    final uri = Uri.parse(googleMapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              // Shop Image with status indicator & badges
              Stack(
                children: [
                  SizedBox(
                    width: 115,
                    height: 130,
                    child: shop.logo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConstants.getImageUrl(shop.logo),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
                              child: const Icon(Icons.storefront_rounded, size: 40, color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholder(isDark),
                          )
                        : _buildPlaceholder(isDark),
                  ),
                  // Status dot
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withAlpha(100),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 24x7 badge
                  if (shop.is24x7)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '24×7',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  // Trending badge
                  if (shop.isTrending)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),

              // Shop Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Verified
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.shopName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (shop.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shop.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextLight : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Rating & Distance
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.amber),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${shop.totalRatings})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                            ),
                          ),
                          if (shop.distanceFormatted != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              shop.distanceFormatted!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Status & Crowd
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              shop.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(shop.crowdEmoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 2),
                          Text(
                            shop.crowdLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Column: Route Directions Button & Arrow
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ROUTE ICON BUTTON
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openDirections(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(80),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (shop.status) {
      case 'open':
        return AppColors.success;
      case 'busy':
        return AppColors.warning;
      case 'closed':
        return AppColors.textLight;
      case 'temporarily_closed':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF334155) : AppColors.primaryLight.withAlpha(40),
      child: const Icon(Icons.storefront_rounded, size: 42, color: AppColors.primary),
    );
  }
}
