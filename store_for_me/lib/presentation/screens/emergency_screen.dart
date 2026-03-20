import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shop_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../widgets/common_widgets.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  final ApiService _api = ApiService();
  final LocationService _locationService = LocationService();
  List<ShopModel> _results = [];
  bool _isLoading = false;
  String? _selectedType;

  final List<Map<String, dynamic>> _emergencyTypes = [
    {'type': 'hospital', 'icon': Icons.local_hospital, 'label': 'Hospitals', 'color': const Color(0xFFDC2626)},
    {'type': 'medical_store', 'icon': Icons.medication, 'label': 'Medical Stores', 'color': const Color(0xFF16A34A)},
    {'type': 'petrol_pump', 'icon': Icons.local_gas_station, 'label': 'Petrol Pumps', 'color': const Color(0xFFF59E0B)},
    {'type': 'mechanic', 'icon': Icons.build, 'label': 'Mechanics', 'color': const Color(0xFF3B82F6)},
  ];

  Future<void> _search(String type) async {
    setState(() { _isLoading = true; _selectedType = type; });
    try {
      final position = await _locationService.getCurrentLocation();
      final response = await _api.getEmergencyServices(
        type: type,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      if (response.data['success'] == true) {
        setState(() {
          _results = (response.data['data'] as List).map((e) => ShopModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // ignore
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Services'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Emergency type cards
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.error.withAlpha(10),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: _emergencyTypes.map((e) {
                final isSelected = _selectedType == e['type'];
                return GestureDetector(
                  onTap: () => _search(e['type']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? (e['color'] as Color) : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? (e['color'] as Color) : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: (e['color'] as Color).withAlpha(60), blurRadius: 10)]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(e['icon'] as IconData, color: isSelected ? Colors.white : e['color'] as Color, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          e['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Finding nearby services...')
                : _results.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.emergency_outlined,
                        title: 'Select an emergency type',
                        subtitle: 'Tap a category above to find nearby services',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final shop = _results[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withAlpha(15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.local_hospital, color: AppColors.error),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(shop.address, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: shop.isOpen ? AppColors.success.withAlpha(20) : AppColors.error.withAlpha(20),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              shop.isOpen ? 'Open' : 'Closed',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: shop.isOpen ? AppColors.success : AppColors.error),
                                            ),
                                          ),
                                          if (shop.distanceFormatted != null) ...[
                                            const SizedBox(width: 8),
                                            Text(shop.distanceFormatted!, style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone, color: AppColors.primary),
                                  onPressed: () {
                                    // Could launch phone dialer
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
