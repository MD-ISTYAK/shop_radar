import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/map_search_service.dart';
import '../providers/shop_provider.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final MapSearchService _searchService = MapSearchService();

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng? _userLocation;
  double _radius = 5.0; // km
  String _selectedCategory = 'All';
  String? _selectedMedical;
  bool _isLoadingMedical = false;
  bool _isLoadingMetro = false;
  List<PlaceResult> _medicalResults = [];

  // Category splits
  static const List<String> _serviceCategories = [
    'Salon', 'Clinic', 'Repair', 'Mechanic', 'Doctor',
  ];
  static const List<String> _medicalOptions = [
    'Nearby Hospital',
    'Blood Bank',
    'Labs',
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = LocationService();
    final pos = await loc.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      });
      _updateRadiusCircle();
      ref.read(shopProvider.notifier).fetchNearbyShops();
    }
  }

  void _updateRadiusCircle() {
    if (_userLocation == null) return;
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('search_radius'),
          center: _userLocation!,
          radius: _radius * 1000,
          fillColor: AppColors.primary.withAlpha(25),
          strokeColor: AppColors.primary.withAlpha(100),
          strokeWidth: 2,
        ),
      };
    });
  }

  void _buildShopMarkers() {
    final shopState = ref.read(shopProvider);
    final shops = shopState.shops;

    final Set<Marker> markers = {};

    for (final shop in shops) {
      if (shop.location == null) continue;

      // Apply category filter
      if (_selectedCategory != 'All' && shop.category != _selectedCategory) continue;

      // Check distance vs radius
      if (shop.distance != null && shop.distance! > _radius) continue;

      final isService = _serviceCategories.contains(shop.category);

      markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.location!.latitude, shop.location!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isService ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: '${isService ? '🛒' : '🏪'} ${shop.shopName}',
            snippet: '${shop.category} • ${shop.statusLabel}${shop.distanceFormatted != null ? ' • ${shop.distanceFormatted}' : ''}',
            onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
          ),
        ),
      );
    }

    // Add medical markers
    for (int i = 0; i < _medicalResults.length; i++) {
      final place = _medicalResults[i];
      markers.add(
        Marker(
          markerId: MarkerId('medical_$i'),
          position: LatLng(place.lat, place.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🏥 ${place.name}',
            snippet: '${place.address}${place.rating != null ? ' • ⭐ ${place.rating}' : ''}',
          ),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  Future<void> _onMedicalSelected(String? type) async {
    if (type == null || _userLocation == null) return;
    setState(() {
      _selectedMedical = type;
      _isLoadingMedical = true;
      _medicalResults = [];
    });

    List<PlaceResult> results;
    switch (type) {
      case 'Nearby Hospital':
        results = await _searchService.findNearbyHospitals(
          _userLocation!.latitude, _userLocation!.longitude,
        );
        break;
      case 'Blood Bank':
        results = await _searchService.findNearbyBloodBanks(
          _userLocation!.latitude, _userLocation!.longitude,
        );
        break;
      case 'Labs':
        results = await _searchService.findNearbyLabs(
          _userLocation!.latitude, _userLocation!.longitude,
        );
        break;
      default:
        results = [];
    }

    if (mounted) {
      setState(() {
        _medicalResults = results;
        _isLoadingMedical = false;
      });
      _buildShopMarkers();
    }
  }

  Future<void> _findNearestMetro() async {
    if (_userLocation == null) return;
    setState(() => _isLoadingMetro = true);

    final metro = await _searchService.findNearestMetro(
      _userLocation!.latitude, _userLocation!.longitude,
    );

    if (metro != null && mounted) {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(metro.lat, metro.lng), 15,
      ));

      setState(() {
        _markers = {
          ..._markers,
          Marker(
            markerId: const MarkerId('nearest_metro'),
            position: LatLng(metro.lat, metro.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: '🚇 ${metro.name}',
              snippet: metro.address,
            ),
          ),
        };
        _isLoadingMetro = false;
      });
    } else {
      if (mounted) {
        setState(() => _isLoadingMetro = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No metro station found nearby')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Rebuild markers when shop data changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shopState.shops.isNotEmpty) _buildShopMarkers();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // Nearby Metro Button
          _isLoadingMetro
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  onPressed: _findNearestMetro,
                  icon: const Icon(Icons.train_rounded),
                  tooltip: 'Nearby Metro',
                ),
        ],
      ),
      body: _userLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            )
          : Column(
              children: [
                // === FILTER BAR ===
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Category / Shop Dropdown
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Category',
                              icon: Icons.store,
                              value: _selectedCategory,
                              items: AppConstants.shopCategories,
                              onChanged: (v) {
                                setState(() {
                                  _selectedCategory = v ?? 'All';
                                  _selectedMedical = null;
                                  _medicalResults = [];
                                });
                                _buildShopMarkers();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Medical Dropdown
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Medical',
                              icon: Icons.local_hospital,
                              value: _selectedMedical,
                              items: _medicalOptions,
                              hintText: 'Medical',
                              onChanged: _onMedicalSelected,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Radius slider
                      Row(
                        children: [
                          const Icon(Icons.radar, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${_radius.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Expanded(
                            child: Slider(
                              value: _radius,
                              min: 1,
                              max: 25,
                              divisions: 48,
                              activeColor: AppColors.primary,
                              label: '${_radius.toStringAsFixed(1)} km',
                              onChanged: (v) {
                                setState(() => _radius = v);
                                _updateRadiusCircle();
                                _buildShopMarkers();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // === LOADING INDICATOR FOR MEDICAL ===
                if (_isLoadingMedical)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: AppColors.info.withAlpha(25),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Searching nearby...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),

                // === GOOGLE MAP ===
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userLocation!,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController.complete(controller);
                    },
                    markers: _markers,
                    circles: _circles,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),

                // === BOTTOM INFO BAR ===
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border(top: BorderSide(color: AppColors.divider.withAlpha(80))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${_markers.length} locations', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      if (_medicalResults.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_hospital, size: 14, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                '${_medicalResults.length} medical',
                                style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Legend
                      _legendDot(AppColors.primaryLight, 'Shops'),
                      const SizedBox(width: 8),
                      _legendDot(AppColors.warning, 'Services'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// Compact filter dropdown widget
class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final String? hintText;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withAlpha(isDark ? 50 : 128)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          isDense: true,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(hintText ?? label, style: const TextStyle(fontSize: 13)),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
