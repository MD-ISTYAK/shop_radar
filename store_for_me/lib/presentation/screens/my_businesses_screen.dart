import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/business_model.dart';
import '../providers/business_provider.dart';

class MyBusinessesScreen extends ConsumerStatefulWidget {
  const MyBusinessesScreen({super.key});

  @override
  ConsumerState<MyBusinessesScreen> createState() => _MyBusinessesScreenState();
}

class _MyBusinessesScreenState extends ConsumerState<MyBusinessesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(businessProvider.notifier).fetchBusinesses());
  }

  @override
  Widget build(BuildContext context) {
    final bizState = ref.watch(businessProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Businesses', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(businessProvider.notifier).fetchBusinesses(),
          ),
        ],
      ),
      body: bizState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bizState.businesses.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref.read(businessProvider.notifier).fetchBusinesses(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: bizState.businesses.length,
                    itemBuilder: (context, index) {
                      final business = bizState.businesses[index];
                      return _buildBusinessTile(business, index);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/start-business'),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Business'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_mall_directory_outlined, size: 64, color: AppColors.primary),
            ),
            SizedBox(height: 24),
            const Text(
              'No Businesses Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first business and reach customers nearby',
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/start-business'),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Start Your Business'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTile(BusinessModel business, int index) {
    final typeConfig = _getTypeConfig(business.businessType);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _navigateToDashboard(business),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: typeConfig.gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (typeConfig.gradient[0] ?? Colors.transparent).withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(typeConfig.icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.businessName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (typeConfig.gradient[0] ?? Colors.transparent).withAlpha(15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              business.typeDisplayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: typeConfig.gradient[0],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(business.status),
                        ],
                      ),
                      if (business.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          business.description,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'suspended':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textLight;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          status[0].toUpperCase() + status.substring(1),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  void _navigateToDashboard(BusinessModel business) {
    switch (business.businessType) {
      case 'shop':
        if (business.shopRefId != null && business.shopRefId!.isNotEmpty) {
          Navigator.pushNamed(context, '/owner-dashboard');
        } else {
          // Shop not yet created, go to add shop
          Navigator.pushNamed(context, '/add-shop');
        }
        break;
      case 'delivery_partner':
        Navigator.pushNamed(context, '/delivery-partner');
        break;
      default:
        // For other business types, show a simple info dialog for now
        _showBusinessDetails(business);
    }
  }

  void _showBusinessDetails(BusinessModel business) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(business.businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.category, 'Type', business.typeDisplayName),
            _buildDetailRow(Icons.info_outline, 'Status', business.statusDisplayName),
            if (business.description.isNotEmpty)
              _buildDetailRow(Icons.description, 'Description', business.description),
            if (business.contactPhone.isNotEmpty)
              _buildDetailRow(Icons.phone, 'Phone', business.contactPhone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Deactivate Business?'),
                      content: const Text('This will deactivate this business. You can re-register later.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Deactivate', style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(businessProvider.notifier).deleteBusiness(business.id);
                  }
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text('Deactivate Business', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
          SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color))),
        ],
      ),
    );
  }

  _TypeConfig _getTypeConfig(String type) {
    switch (type) {
      case 'shop':
        return _TypeConfig(Icons.storefront_rounded, [const Color(0xFF6C63FF), const Color(0xFF4834DF)]);
      case 'cart_service':
        return _TypeConfig(Icons.shopping_cart_rounded, [const Color(0xFF00B894), const Color(0xFF00865A)]);
      case 'delivery_partner':
        return _TypeConfig(Icons.delivery_dining_rounded, [const Color(0xFFF39C12), const Color(0xFFE67E22)]);
      case 'freelancer':
        return _TypeConfig(Icons.handyman_rounded, [const Color(0xFFE84393), const Color(0xFFB83280)]);
      default:
        return _TypeConfig(Icons.business_center_rounded, [const Color(0xFF636E72), const Color(0xFF2D3436)]);
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final List<Color> gradient;
  _TypeConfig(this.icon, this.gradient);
}









