import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/order_provider.dart';
import '../providers/token_provider.dart';
import '../../data/models/order_model.dart';
import '../widgets/common_widgets.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(orderProvider.notifier).fetchMyOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
            Tab(text: 'Queue'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Orders
          _buildOrderList(orderState.activeOrders, orderState.isLoading, 'No active orders'),
          // Order History
          _buildOrderList(orderState.orderHistory, orderState.isLoading, 'No order history yet'),
          // Queue Tokens
          _buildQueueTab(),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, bool isLoading, String emptyMessage) {
    if (isLoading) return const LoadingIndicator(message: 'Loading orders...');
    if (orders.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.shopping_bag_outlined,
        title: emptyMessage,
        subtitle: 'Your orders will appear here',
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).fetchMyOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final status = order.status;
          final shopName = order.shopName;
          final total = order.totalAmount;
          final items = order.items;
          final createdAt = order.createdAt;

          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/order-details', arguments: order),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.statusLabel.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getStatusColor(status)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${items.length} items • ₹${total.toStringAsFixed(0)}', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppColors.divider),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Tap to view details & tracking', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineDot(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: active ? AppColors.success : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: active ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 8, color: active ? AppColors.success : AppColors.textLight)),
      ],
    );
  }

  Widget _buildTimelineLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? AppColors.success : AppColors.divider,
      ),
    );
  }

  Widget _buildQueueTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 64, color: AppColors.textLight),
          const SizedBox(height: 12),
          const Text('Queue Tokens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Your active queue tokens will appear here', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.info;
      case 'preparing': return AppColors.accent;
      case 'ready': return AppColors.success;
      case 'out_for_delivery': return AppColors.primary;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textLight;
    }
  }
}
