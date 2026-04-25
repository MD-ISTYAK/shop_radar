import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/order_provider.dart';
import '../../data/models/order_model.dart';
import '../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class OwnerOrdersScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final bool isTab;
  const OwnerOrdersScreen({super.key, this.scrollController, this.isTab = false});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
    Future.microtask(() => ref.read(orderProvider.notifier).fetchShopOrders());
  }

  void _onSearchChanged() {
    ref.read(orderProvider.notifier).fetchShopOrders(search: _searchController.text);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);

    if (orderState.isLoading && orderState.activeOrders.isEmpty && _searchController.text.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeOrders = orderState.activeOrders;
    final newOrders = activeOrders.where((o) => o.status == 'pending').toList();
    final preparingOrders = activeOrders.where((o) => o.status == 'accepted').toList();
    final packedOrders = activeOrders.where((o) => o.status == 'packed' || o.status == 'ready' || o.status == 'delivery_assigned').toList();
    final completedOrders = activeOrders.where((o) => o.status == 'out_for_delivery' || o.isCompleted).toList();

    final content = TabBarView(
      controller: _tabController,
      children: [
        _buildOrderList(newOrders, emptyMessage: 'No new incoming orders'),
        _buildOrderList(preparingOrders, emptyMessage: 'No orders are being prepared'),
        _buildOrderList(packedOrders, emptyMessage: 'No packed or ready orders'),
        _buildOrderList(completedOrders, emptyMessage: 'No recent history'),
      ],
    );

    if (widget.isTab) {
      return Column(
        children: [
          // New Search & Scanner Bar for Shell Mode
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(color: AppColors.shadow.withAlpha(10), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search order ID (8 chars)...',
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/order-scanner'),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabs: [
              Tab(text: 'New (${newOrders.length})'),
              Tab(text: 'Preparing (${preparingOrders.length})'),
              Tab(text: 'Packed (${packedOrders.length})'),
              Tab(text: 'History (${completedOrders.length})'),
            ],
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search order ID (8 chars)...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16),
              ),
              style: const TextStyle(color: AppColors.primary),
            )
          : const Text('Manage Orders'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(context, '/order-scanner'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: [
            Tab(text: 'New (${newOrders.length})'),
            Tab(text: 'Preparing (${preparingOrders.length})'),
            Tab(text: 'Packed (${packedOrders.length})'),
            Tab(text: 'History (${completedOrders.length})'),
          ],
        ),
      ),
      body: content,
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, {required String emptyMessage}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
            SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).fetchShopOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/owner-order-details', arguments: order).then((_) {
              ref.read(orderProvider.notifier).fetchShopOrders();
            }),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order ID: ${order.shortId}', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_getStatusColor(order.status) ?? Colors.transparent).withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.statusLabel.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getStatusColor(order.status)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('${order.items.length} items • ₹${order.totalAmount.toStringAsFixed(0)}', 
                         style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          order.deliveryType == 'shop_pickup' ? 'Shop Pickup' : 'Home Delivery',
                          style: TextStyle(color: order.deliveryType == 'shop_pickup' ? AppColors.accent : AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('hh:mm a  dd-MM-yyyy').format(order.createdAt.toLocal()), 
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Manage Order', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'accepted': return AppColors.info;
      case 'packed': case 'ready': return AppColors.success;
      case 'out_for_delivery': return AppColors.primary;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textLight;
    }
  }
}









