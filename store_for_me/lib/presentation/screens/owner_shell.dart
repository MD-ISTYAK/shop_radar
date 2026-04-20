import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/shop_provider.dart';
import '../providers/product_provider.dart';
import 'owner_dashboard_screen.dart';
import 'owner_orders_screen.dart';
import 'settings_screen.dart';
import '../widgets/owner_shop_content.dart';
import '../widgets/owner_story_content.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late ScrollController _scrollController;
  bool _isHeaderVisible = true;
  double _headerOffset = 0;
  final double _headerHeight = 80;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    
    Future.microtask(() {
      ref.read(shopProvider.notifier).fetchOwnerShop();
      ref.read(productProvider.notifier).fetchOwnerProducts();
    });
  }

  void _scrollListener() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.forward) {
      if (!_isHeaderVisible) setState(() => _isHeaderVisible = true);
    } else if (direction == ScrollDirection.reverse) {
      if (_isHeaderVisible && _scrollController.offset > _headerHeight) {
        setState(() => _isHeaderVisible = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _isHeaderVisible = true; // Show header when switching tabs
    });
  }

  Widget _getSelectedScreen() {
    switch (_currentIndex) {
      case 0:
        return OwnerDashboardScreen(scrollController: _scrollController);
      case 1:
        return OwnerShopContent(scrollController: _scrollController);
      case 2:
        return OwnerOrdersScreen(scrollController: _scrollController, isTab: true);
      case 3:
        return OwnerStoryContent(scrollController: _scrollController);
      case 4:
        return const SettingsScreen();
      default:
        return OwnerDashboardScreen(scrollController: _scrollController);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double totalHeaderHeight = _headerHeight + topPadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Screen Content
          Padding(
            padding: EdgeInsets.only(top: _isHeaderVisible ? totalHeaderHeight : 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _getSelectedScreen(),
            ),
          ),

          // Premium Flexible Ribbon (Header)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            top: _isHeaderVisible ? 0 : -totalHeaderHeight,
            left: 0,
            right: 0,
            child: Container(
              height: totalHeaderHeight,
              padding: EdgeInsets.fromLTRB(20, topPadding, 12, 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(100),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Logo / Radar Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
                    ),
                    child: const Icon(Icons.radar_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  // App Title & Subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shop Radar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: AppColors.success, blurRadius: 4, spreadRadius: 1),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Owner Panel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Icons
                  Row(
                    children: [
                      _HeaderActionIcon(
                        icon: Icons.notifications_none_rounded,
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                      ),
                      _HeaderActionIcon(
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () => Navigator.pushNamed(context, '/chat-list'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
                _buildNavItem(1, Icons.storefront_outlined, Icons.storefront_rounded, 'Shop'),
                _buildNavItem(2, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Orders'),
                _buildNavItem(3, Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Story'),
                _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
