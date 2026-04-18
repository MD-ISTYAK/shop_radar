import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/shop_provider.dart';
import '../widgets/common_widgets.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _selectedRadius = 3.0;
  bool _openNowOnly = false;
  bool _nightMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(shopProvider.notifier).fetchNearbyShops());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Discover', style: TextStyle(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_nightMode ? Icons.nightlight_round : Icons.nightlight_outlined,
              color: _nightMode ? AppColors.warning : null),
            onPressed: () => setState(() => _nightMode = !_nightMode),
            tooltip: 'Night Mode Shops',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Map View'),
            Tab(text: 'Browse'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Map View tab — placeholder (Google Maps needs platform setup)
          _buildMapPlaceholder(shopState),
          // Browse tab
          _buildBrowseView(shopState),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(dynamic shopState) {
    return RefreshIndicator(
      onRefresh: () => ref.read(shopProvider.notifier).fetchNearbyShops(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Radius selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text('Radius:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _selectedRadius,
                      min: 0.5,
                      max: 10,
                      divisions: 19,
                      label: '${_selectedRadius.toStringAsFixed(1)} km',
                      onChanged: (v) => setState(() => _selectedRadius = v),
                      onChangeEnd: (v) {
                        ref.read(shopProvider.notifier).fetchNearbyShops();
                      },
                    ),
                  ),
                  Text('${_selectedRadius.toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildLegendDot(Colors.green, 'Open'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.orange, 'Busy'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.grey, 'Closed'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.red, 'Temp Closed'),
                  const SizedBox(width: 16),
                  _buildLegendDot(Colors.blue, '24×7'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Map placeholder
            Container(
              height: 400, // Fixed height for map placeholder in scrollable view
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: AppColors.textLight),
                    const SizedBox(height: 12),
                    const Text(
                      'Google Maps View',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${shopState.shops.length} shops found nearby',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: shopState.shops.take(5).map<Widget>((shop) {
                        final color = _getStatusColor(shop.status);
                        return Chip(
                          avatar: CircleAvatar(backgroundColor: color, radius: 6),
                          label: Text(shop.shopName, style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppColors.background,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseView(dynamic shopState) {
    return Column(
      children: [
        // Category grid
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: AppConstants.shopCategories.length.clamp(0, 12),
            itemBuilder: (context, index) {
              final cat = AppConstants.shopCategories[index];
              final iconCode = AppConstants.categoryIcons[cat] ?? 0xe148;
              final isSelected = shopState.selectedCategory == cat;
              return GestureDetector(
                onTap: () => ref.read(shopProvider.notifier).setCategory(cat),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withAlpha(25) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconData(iconCode, fontFamily: 'MaterialIcons'),
                        color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
                      const SizedBox(height: 6),
                      Text(cat, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary),
                        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Shop list
        Expanded(
          child: shopState.isLoading
              ? const LoadingIndicator(message: 'Searching...')
              : shopState.shops.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => ref.read(shopProvider.notifier).fetchNearbyShops(),
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: const EmptyStateWidget(icon: Icons.store_outlined, title: 'No shops found', subtitle: 'Try another category'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(shopProvider.notifier).fetchNearbyShops(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: shopState.shops.length,
                        itemBuilder: (context, index) {
                          final shop = shopState.shops[index];
                          return ListTile(
                            leading: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: _getStatusColor(shop.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${shop.category} • ${shop.crowdLabel}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: AppColors.warning, size: 16),
                                    Text(' ${shop.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                                Text(shop.statusLabel, style: TextStyle(fontSize: 11, color: _getStatusColor(shop.status), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.green;
      case 'busy': return Colors.orange;
      case 'closed': return Colors.grey;
      case 'temporarily_closed': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Open Now Only'),
                  value: _openNowOnly,
                  onChanged: (v) => setSheetState(() => _openNowOnly = v),
                  activeColor: AppColors.primary,
                ),
                SwitchListTile(
                  title: const Text('Night Mode (10 PM - 6 AM)'),
                  subtitle: const Text('Show only shops open late'),
                  value: _nightMode,
                  onChanged: (v) => setSheetState(() => _nightMode = v),
                  activeColor: AppColors.warning,
                ),
                const SizedBox(height: 8),
                const Text('Distance Radius', style: TextStyle(fontWeight: FontWeight.w600)),
                Slider(
                  value: _selectedRadius,
                  min: 0.5, max: 10, divisions: 19,
                  label: '${_selectedRadius.toStringAsFixed(1)} km',
                  onChanged: (v) => setSheetState(() => _selectedRadius = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                      ref.read(shopProvider.notifier).fetchNearbyShops();
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
