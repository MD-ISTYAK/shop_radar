import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/shop_provider.dart';
import '../widgets/premium_widgets.dart';

class ProductListingScreen extends ConsumerStatefulWidget {
  final String category;

  const ProductListingScreen({super.key, required this.category});

  @override
  ConsumerState<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopProvider.notifier).setCategory(widget.category);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category == 'All' ? 'Discover Shops' : widget.category,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                PremiumTextField(
                  controller: _searchController,
                  hintText: 'Search in ${widget.category}...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (v) => ref.read(shopProvider.notifier).setSearchQuery(v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.shopCategories.length,
                    itemBuilder: (context, index) {
                      final cat = AppConstants.shopCategories[index];
                      final isSelected = shopState.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(cat),
                          onSelected: (v) => ref.read(shopProvider.notifier).setCategory(cat),
                          selectedColor: AppColors.primary,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          backgroundColor: isDark ? AppColors.darkCard : Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: shopState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : shopState.shops.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: shopState.shops.length,
                        itemBuilder: (context, index) {
                          final shop = shopState.shops[index];
                          return _buildShopCard(shop).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(dynamic shop) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: shop.logo,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.store)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.shopName,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.isVerified)
                        const Icon(Icons.verified, color: AppColors.primary, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.address,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoTag(Icons.star_rounded, shop.rating.toStringAsFixed(1), Colors.amber),
                      const SizedBox(width: 8),
                      _buildInfoTag(Icons.location_on_rounded, shop.distanceFormatted ?? 'Nearby', AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight.withOpacity(0.3)),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No shops found',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your category or search query.',
            style: GoogleFonts.inter(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
