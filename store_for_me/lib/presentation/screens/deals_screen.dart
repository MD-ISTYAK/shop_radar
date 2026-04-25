import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../providers/deal_provider.dart';
import '../widgets/common_widgets.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(dealProvider.notifier).fetchNearbyDeals();
      ref.read(dealProvider.notifier).fetchTrendingDeals();
      ref.read(dealProvider.notifier).fetchSavedDeals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dealState = ref.watch(dealProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Deals & Offers', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nearby'),
            Tab(text: 'Trending 🔥'),
            Tab(text: 'Saved'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDealList(dealState.deals, dealState.isLoading, 'No deals nearby'),
          _buildDealList(dealState.trendingDeals, dealState.isLoading, 'No trending deals'),
          _buildDealList(dealState.savedDeals, dealState.isLoading, 'No saved deals'),
        ],
      ),
    );
  }

  Widget _buildDealList(List deals, bool isLoading, String emptyMsg) {
    if (isLoading) return const LoadingIndicator(message: 'Loading deals...');
    if (deals.isEmpty) {
      return EmptyStateWidget(icon: Icons.local_offer_outlined, title: emptyMsg, subtitle: 'Check back later for new deals');
    }
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dealProvider.notifier).fetchNearbyDeals();
        await ref.read(dealProvider.notifier).fetchTrendingDeals();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deals.length,
        itemBuilder: (context, index) {
          final deal = deals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${deal.discountPercent}% OFF',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(deal.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: Icon(
                          deal.isSavedBy('') ? Icons.bookmark : Icons.bookmark_border,
                          color: AppColors.primary,
                        ),
                        onPressed: () => ref.read(dealProvider.notifier).toggleSaveDeal(deal.id),
                      ),
                    ],
                  ),
                  if (deal.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(deal.description, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(deal.shopName, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      const Spacer(),
                      Text(
                        '₹${deal.originalPrice.toInt()}',
                        style: TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${deal.dealPrice.toInt()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Expiry timer
                  Row(
                    children: [
                      Icon(
                        deal.isExpired ? Icons.timer_off : Icons.timer,
                        size: 14,
                        color: deal.isExpired ? AppColors.error : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deal.isExpired ? 'Expired' : _formatTimeRemaining(deal.timeRemaining),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: deal.isExpired ? AppColors.error : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (60 * index).ms);
        },
      ),
    );
  }

  String _formatTimeRemaining(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    if (d.inMinutes > 0) return '${d.inMinutes}m left';
    return 'Expiring soon';
  }
}







