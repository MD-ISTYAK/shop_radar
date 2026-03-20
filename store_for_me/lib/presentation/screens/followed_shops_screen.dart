import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shop_model.dart';
import '../../services/api_service.dart';
import '../widgets/common_widgets.dart';

class FollowedShopsScreen extends ConsumerStatefulWidget {
  const FollowedShopsScreen({super.key});

  @override
  ConsumerState<FollowedShopsScreen> createState() => _FollowedShopsScreenState();
}

class _FollowedShopsScreenState extends ConsumerState<FollowedShopsScreen> {
  final ApiService _api = ApiService();
  List<ShopModel> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowedShops();
  }

  Future<void> _fetchFollowedShops() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getFollowedShops();
      if (response.data['success'] == true) {
        setState(() {
          _shops = (response.data['data'] as List).map((e) => ShopModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // ignore
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Followed Shops')),
      body: _isLoading
          ? const LoadingIndicator()
          : _shops.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.favorite_border,
                  title: 'Not following any shops',
                  subtitle: 'Follow shops to see them here and get their updates in your feed',
                )
              : RefreshIndicator(
                  onRefresh: _fetchFollowedShops,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shops.length,
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Shop logo
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: shop.logo.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: '${AppConstants.uploadsUrl}${shop.logo}',
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(
                                              color: AppColors.primaryLight.withAlpha(30),
                                              child: const Icon(Icons.store, color: AppColors.primary),
                                            ),
                                          )
                                        : Container(
                                            color: AppColors.primaryLight.withAlpha(30),
                                            child: const Icon(Icons.store, color: AppColors.primary),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Shop info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shop.shopName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight.withAlpha(20),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              shop.category,
                                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: shop.isOpen ? AppColors.success.withAlpha(20) : AppColors.error.withAlpha(20),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              shop.statusLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: shop.isOpen ? AppColors.success : AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (shop.address.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          shop.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textLight),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
