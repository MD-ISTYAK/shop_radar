import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/shop_model.dart';
import '../../core/theme/app_theme.dart';
import '../providers/shop_provider.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopProvider.notifier).fetchNearbyShops();
    });
  }

  void _updateMarkers(List<ShopModel> shops) {
    _markers.clear();
    for (final shop in shops) {
      if (shop.location != null) {
        _markers.add(
          Marker(
            point: LatLng(shop.location!.latitude, shop.location!.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 20),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);

    ref.listen(shopProvider.select((s) => s.userLocation), (previous, next) {
      if (next != null) {
        _mapController.move(LatLng(next.latitude, next.longitude), 14);
      }
    });

    _updateMarkers(shopState.shops);

    LatLng initialPosition = const LatLng(28.6139, 77.2090); // Default to Delhi
    if (shopState.userLocation != null) {
      initialPosition = LatLng(shopState.userLocation!.latitude, shopState.userLocation!.longitude);
    } else if (shopState.shops.isNotEmpty && shopState.shops.first.location != null) {
      initialPosition = LatLng(shopState.shops.first.location!.latitude, shopState.shops.first.location!.longitude);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Shops Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialPosition,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.store_for_me.app',
                ),
                MarkerLayer(markers: _markers),
                if (shopState.userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(shopState.userLocation!.latitude, shopState.userLocation!.longitude),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Shop list at bottom
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Shops Near You',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: shopState.shops.length,
                      itemBuilder: (context, index) {
                        final shop = shopState.shops[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight.withAlpha(51),
                            child: const Icon(Icons.store, color: AppColors.primary),
                          ),
                          title: Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(shop.distanceFormatted ?? shop.address),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: shop.isOpen ? AppColors.success.withAlpha(26) : AppColors.error.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              shop.isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: shop.isOpen ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
