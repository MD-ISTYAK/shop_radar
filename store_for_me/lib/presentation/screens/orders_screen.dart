import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/order_provider.dart';
import '../providers/token_provider.dart';
import '../../data/models/order_model.dart';
import '../widgets/common_widgets.dart';
import '../../core/utils/time_utils.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(orderProvider.notifier).fetchMyOrders();
      ref.read(tokenProvider.notifier).fetchMyToken();
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
    final tokenState = ref.watch(tokenProvider);

    final activeCount = orderState.activeOrders.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(orderProvider.notifier).fetchMyOrders();
              ref.read(tokenProvider.notifier).fetchMyToken();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Active Orders'),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Order History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Active Orders List with Live Queue Status
          _buildActiveOrdersView(orderState, tokenState),

          // 2. Order History List
          _buildOrderHistoryView(orderState),
        ],
      ),
    );
  }

  // --- Active Orders View ---
  Widget _buildActiveOrdersView(OrderState orderState, TokenState tokenState) {
    if (orderState.isLoading) {
      return const LoadingIndicator(message: 'Fetching live orders...');
    }

    final activeOrders = orderState.activeOrders;

    if (activeOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(orderProvider.notifier).fetchMyOrders();
          await ref.read(tokenProvider.notifier).fetchMyToken();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        size: 64, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Active Orders Right Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Place an order from nearby shops to track real-time queue position & status here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/discover'),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Explore Nearby Shops'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(orderProvider.notifier).fetchMyOrders();
        await ref.read(tokenProvider.notifier).fetchMyToken();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          final order = activeOrders[index];
          return _buildOrderCard(order, isActive: true);
        },
      ),
    );
  }

  // --- Order History View ---
  Widget _buildOrderHistoryView(OrderState orderState) {
    if (orderState.isLoading) {
      return const LoadingIndicator(message: 'Loading order history...');
    }

    final historyOrders = orderState.orderHistory;

    if (historyOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(orderProvider.notifier).fetchMyOrders(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history,
                        size: 64,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Past Orders Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed and delivered orders will be saved here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).fetchMyOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyOrders.length,
        itemBuilder: (context, index) {
          final order = historyOrders[index];
          return _buildOrderCard(order, isActive: false);
        },
      ),
    );
  }

  // --- Professional Order Card Component with In-Line Queue Status ---
  Widget _buildOrderCard(OrderModel order, {required bool isActive}) {
    final statusColor = _getStatusColor(order.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? statusColor.withAlpha(60)
              : (isDark ? Colors.white10 : Colors.black.withAlpha(12)),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, '/order-details', arguments: order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Shop Name & Status Badge
                Row(
                  children: [
                    // Shop Logo / Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: order.shopLogo.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: AppConstants.getImageUrl(order.shopLogo),
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(
                                    Icons.storefront,
                                    color: AppColors.primary),
                              ),
                            )
                          : const Icon(Icons.storefront,
                              color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.shopName.isNotEmpty
                                ? order.shopName
                                : 'Shop Radar Merchant',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order #${order.shortId} • ${TimeUtils.formatIST(order.createdAt, pattern: 'MMM dd, hh:mm a')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.statusLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // 2. LIVE QUEUE & PROGRESS STATUS STEPPER (For Active Orders)
                if (isActive) ...[
                  _buildLiveQueueTracker(order),
                  const SizedBox(height: 14),
                ],

                // 3. Items Summary Preview
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.items.isNotEmpty
                            ? order.items
                                .map((item) => '${item.quantity}x ${item.name}')
                                .join(', ')
                            : '${order.items.length} Items',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Action Bar
                Row(
                  children: [
                    if (order.pickupCode.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withAlpha(80)),
                        ),
                        child: Text(
                          'Pickup OTP: ${order.pickupCode}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber),
                        ),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),

                    if (order.shopPhone.isNotEmpty)
                      IconButton(
                        onPressed: () async {
                          final uri = Uri.parse('tel:${order.shopPhone}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.phone_outlined,
                            size: 18, color: AppColors.primary),
                        tooltip: 'Call Merchant',
                      ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, '/order-details',
                          arguments: order),
                      icon: const Icon(Icons.near_me, size: 14),
                      label: const Text('Live Tracking',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Embedded Live Queue & Order Tracker Component ---
  Widget _buildLiveQueueTracker(OrderModel order) {
    final statusIndex = _getStageIndex(order.status);
    final stages = [
      {'label': 'Placed', 'icon': Icons.receipt_long},
      {'label': 'Accepted', 'icon': Icons.check_circle_outline},
      {'label': 'In Queue', 'icon': Icons.hourglass_top},
      {'label': 'Ready', 'icon': Icons.inventory_2_outlined},
      {'label': 'Out', 'icon': Icons.local_shipping_outlined},
    ];

    final queueText = _getQueueDescription(order);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  queueText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE STATUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Stepper Bar
          Row(
            children: List.generate(stages.length * 2 - 1, (index) {
              if (index.isEven) {
                final stageIdx = index ~/ 2;
                final isPassed = stageIdx <= statusIndex;
                final isCurrent = stageIdx == statusIndex;
                final stage = stages[stageIdx];

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppColors.primary
                              : Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPassed
                                ? AppColors.primary
                                : Colors.grey.withAlpha(80),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          stage['icon'] as IconData,
                          size: 12,
                          color: isPassed ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stage['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isPassed
                              ? AppColors.primary
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final lineIdx = index ~/ 2;
                final isPassed = lineIdx < statusIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: isPassed
                        ? AppColors.primary
                        : Colors.grey.withAlpha(60),
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  int _getStageIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
      case 'confirmed':
        return 1;
      case 'preparing':
      case 'in_queue':
      case 'packed':
        return 2;
      case 'ready':
      case 'delivery_assigned':
        return 3;
      case 'picked_up':
      case 'out_for_delivery':
      case 'delivered':
        return 4;
      default:
        return 1;
    }
  }

  String _getQueueDescription(OrderModel order) {
    switch (order.status) {
      case 'pending':
        return 'Order Sent • Waiting merchant acceptance';
      case 'accepted':
      case 'confirmed':
        return 'Order Accepted • Assigned to Merchant Queue';
      case 'preparing':
      case 'in_queue':
      case 'packed':
        return 'In Kitchen / Store Preparation (~10-15 mins est.)';
      case 'ready':
        return order.deliveryType == 'self_pickup'
            ? 'Order Ready! Present Pickup Code at Counter'
            : 'Order Packed! Waiting pickup by delivery partner';
      case 'out_for_delivery':
      case 'picked_up':
        return 'Out for Delivery • Partner is on the way!';
      case 'delivered':
        return 'Delivered Successfully';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Live Order Queue';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
      case 'in_queue':
      case 'packed':
        return AppColors.accent;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
      case 'picked_up':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }
}
