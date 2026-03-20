import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/shop_card.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopProvider.notifier).fetchNearbyShops();
      ref.read(cartProvider.notifier).fetchCart();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${authState.user?.name.split(' ').first ?? 'there'}! 👋',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover nearby shops',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Followed shops
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/followed-shops'),
                    icon: const Icon(Icons.favorite_outlined, size: 24, color: AppColors.error),
                    tooltip: 'Followed Shops',
                  ),
                  // Chat
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/chat-list'),
                    icon: const Icon(Icons.chat_outlined, size: 24),
                    tooltip: 'Messages',
                  ),
                  // Notifications
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/notifications'),
                        icon: const Icon(Icons.notifications_outlined, size: 26),
                      ),
                      if (ref.watch(notificationProvider).unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                            child: Text(
                              '${ref.watch(notificationProvider).unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Cart icon
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/cart'),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 26),
                      ),
                      if (cartState.itemCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartState.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Logout
                  IconButton(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: const Icon(Icons.logout, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(shopProvider.notifier).setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search shops...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(shopProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categories
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppConstants.shopCategories.length,
                itemBuilder: (context, index) {
                  final category = AppConstants.shopCategories[index];
                  final isSelected = shopState.selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      backgroundColor: AppColors.card,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      onSelected: (_) {
                        ref.read(shopProvider.notifier).setCategory(category);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Shops list
            Expanded(
              child: shopState.isLoading
                  ? const LoadingIndicator(message: 'Finding nearby shops...')
                  : shopState.shops.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.store_outlined,
                          title: 'No shops found',
                          subtitle: 'Try a different search or category',
                          buttonText: 'Refresh',
                          onButtonPressed: () {
                            ref.read(shopProvider.notifier).fetchNearbyShops();
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(shopProvider.notifier).fetchNearbyShops(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: shopState.shops.length,
                            itemBuilder: (context, index) {
                              final shop = shopState.shops[index];
                              return ShopCard(
                                shop: shop,
                                onTap: () {
                                  Navigator.pushNamed(context, '/shop-details', arguments: shop.id);
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 1: Navigator.pushNamed(context, '/feed'); break;
            case 2: Navigator.pushNamed(context, '/map-view'); break;
            case 3: Navigator.pushNamed(context, '/emergency'); break;
            case 4: Navigator.pushNamed(context, '/cart'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.emergency_outlined), selectedIcon: Icon(Icons.emergency), label: 'SOS'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Cart'),
        ],
      ),
    );
  }
}
