import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/shop_provider.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shopProvider.notifier).fetchNearbyShops());
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Map View', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Map placeholder — Google Maps requires platform-specific setup
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, size: 64, color: AppColors.primary),
                    SizedBox(height: 12),
                    const Text(
                      'Google Maps',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${shopState.shops.length} shops nearby',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your Google Maps API key and\nplatform config to enable maps',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Shop list
          Expanded(
            flex: 1,
            child: shopState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : shopState.shops.isEmpty
                    ? const Center(child: Text('No shops found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: shopState.shops.length,
                        itemBuilder: (context, index) {
                          final shop = shopState.shops[index];
                          return ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: shop.isOpen ? AppColors.success : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${shop.category} • ${shop.statusLabel}'),
                            trailing: shop.distanceFormatted != null
                                ? Text(shop.distanceFormatted!, style: const TextStyle(fontSize: 12))
                                : null,
                            onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
                            dense: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}







