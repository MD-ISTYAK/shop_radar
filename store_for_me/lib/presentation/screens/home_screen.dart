import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shop_model.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
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

  // Active Main Business Type
  String _selectedBusinessType = 'All'; // 'All', 'Shops & Retail', 'Services & Repair', 'Street Carts & Stalls', 'Gyms & Fitness', 'Food & Dining'
  String _selectedSubCategory = 'All'; // Sub-category selected for current business type

  // Quick Toggles
  bool _filterOpenNow = false;
  bool _filterTopRated = false; // rating >= 4.0
  bool _filterNearestOnly = false; // distance <= 3km
  String _sortBy = 'distance'; // 'distance', 'rating', 'name'
  double _maxDistanceKm = 10.0;
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(shopProvider.notifier).fetchNearbyShops();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get current sub-category list based on selected business type
  List<String> get _currentSubCategories {
    return AppConstants.subCategoriesByBusinessType[_selectedBusinessType] ??
        AppConstants.subCategoriesByBusinessType['All']!;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedBusinessType != 'All') {
      count++;
    }
    if (_selectedSubCategory != 'All' &&
        !_selectedSubCategory.startsWith('All ')) {
      count++;
    }
    if (_filterOpenNow) {
      count++;
    }
    if (_filterTopRated || _minRating > 0) {
      count++;
    }
    if (_filterNearestOnly) {
      count++;
    }
    if (_sortBy != 'distance') {
      count++;
    }
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedBusinessType = 'All';
      _selectedSubCategory = 'All';
      _filterOpenNow = false;
      _filterTopRated = false;
      _filterNearestOnly = false;
      _sortBy = 'distance';
      _maxDistanceKm = 10.0;
      _minRating = 0.0;
    });
    ref.read(shopProvider.notifier).setCategory('All');
  }

  void _onSelectBusinessType(String type) {
    setState(() {
      _selectedBusinessType = type;
      final subs = _currentSubCategories;
      _selectedSubCategory = subs.first; // Default to 'All Shops', 'All Services', etc.
    });

    if (type == 'All') {
      ref.read(shopProvider.notifier).setCategory('All');
    } else {
      ref.read(shopProvider.notifier).setCategory(type);
    }
  }

  List<ShopModel> _applyFilters(List<ShopModel> originalShops) {
    List<ShopModel> result = originalShops.where((shop) {
      final cat = shop.category.toLowerCase();

      // 1. Business Type Scope
      if (_selectedBusinessType == 'Shops & Retail') {
        if (cat.contains('repair') || cat.contains('carts') || cat.contains('salon') || cat.contains('gym')) {
          return false;
        }
      } else if (_selectedBusinessType == 'Services & Repair') {
        if (!cat.contains('repair') && !cat.contains('plumbing') && !cat.contains('mechanic') && !cat.contains('home services') && !cat.contains('clinic') && !cat.contains('salon')) {
          return false;
        }
      } else if (_selectedBusinessType == 'Street Carts & Stalls') {
        if (!cat.contains('carts') && !cat.contains('tea') && !cat.contains('vendor') && !cat.contains('stall')) {
          return false;
        }
      } else if (_selectedBusinessType == 'Gyms & Fitness') {
        if (!cat.contains('gym') && !cat.contains('fitness')) {
          return false;
        }
      } else if (_selectedBusinessType == 'Food & Dining') {
        if (!cat.contains('food') && !cat.contains('restaurant') && !cat.contains('bakery') && !cat.contains('cafe')) {
          return false;
        }
      }

      // 2. Sub-category Keyword Match (Simple for Indian User)
      if (_selectedSubCategory != 'All' &&
          !_selectedSubCategory.startsWith('All ')) {
        final subKeyword = _selectedSubCategory
            .replaceAll('&', '')
            .split(' ')
            .first
            .toLowerCase();
        if (!cat.contains(subKeyword) && !shop.shopName.toLowerCase().contains(subKeyword)) {
          return false;
        }
      }

      // 3. Open Now Filter
      if (_filterOpenNow && !shop.isOpen) {
        return false;
      }

      // 4. Rating Filter
      final targetRating = _filterTopRated ? 4.0 : _minRating;
      if (targetRating > 0 && shop.rating < targetRating) {
        return false;
      }

      // 5. Distance Filter
      final targetDistance = _filterNearestOnly ? 3.0 : _maxDistanceKm;
      if ((shop.distance ?? 0.0) > targetDistance) {
        return false;
      }

      return true;
    }).toList();

    // Sorting
    if (_sortBy == 'rating') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'name') {
      result.sort((a, b) => a.shopName.compareTo(b.shopName));
    } else {
      result.sort((a, b) => (a.distance ?? 0.0).compareTo(b.distance ?? 0.0));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredShops = _applyFilters(shopState.shops);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(shopProvider.notifier).fetchNearbyShops();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // === 1. TOP HEADER & SEARCH BAR ===
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                          : [AppColors.primary, const Color(0xFF3730A3)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Namaste, ${authState.user?.name.split(' ').first ?? 'Ji'}! 🙏',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                                const SizedBox(height: 2),
                                const Text(
                                  'Dukaan, Sabzi/Chai Cart & AC Repair In Your Area',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notifications Bell
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pushNamed(context, '/notifications'),
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Cart Icon
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pushNamed(context, '/cart'),
                              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                              tooltip: 'Cart',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search & Filter Trigger Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDark ? 80 : 30),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => ref.read(shopProvider.notifier).setSearchQuery(v),
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search Kirana, Chai Stall, AC Repair...',
                                  hintStyle: TextStyle(
                                    color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                                    size: 22,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
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
                          const SizedBox(width: 8),
                          // Full Filter Bottom Sheet Trigger with Active Count
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: _activeFilterCount > 0
                                      ? AppColors.primary
                                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.tune_rounded,
                                    color: _activeFilterCount > 0
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                  onPressed: () => _showFilterBottomSheet(context),
                                  tooltip: 'Filter Options',
                                ),
                              ),
                              if (_activeFilterCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_activeFilterCount',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // === 2. MAIN TYPE FILTER TABS (Shops vs Carts vs Services) ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeTab('All Listings 🌐', 'All'),
                          _buildTypeTab('Shops / Dukaan 🛒', 'Shops & Retail'),
                          _buildTypeTab('Carts & Stalls 🍵', 'Street Carts & Stalls'),
                          _buildTypeTab('Services & Repair 🛠️', 'Services & Repair'),
                          _buildTypeTab('Gym & Fitness 🏋️', 'Gyms & Fitness'),
                          _buildTypeTab('Food & Dining 🍕', 'Food & Dining'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // === 3. DYNAMIC SUB-CATEGORY CHIPS (Changes based on selected Main Type!) ===
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            _getCategorySectionHeader(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentSubCategories.length} Options',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _currentSubCategories.length,
                        itemBuilder: (context, index) {
                          final subCat = _currentSubCategories[index];
                          final isSelected = _selectedSubCategory == subCat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                subCat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.textSecondary),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              showCheckmark: false,
                              onSelected: (_) {
                                setState(() => _selectedSubCategory = subCat);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // === 4. QUICK TOGGLE PILLS ===
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Open Now Toggle Pill
                      _buildFilterPill(
                        icon: Icons.flash_on,
                        label: 'Open Now / Dukaan Khuli Hai 🟢',
                        isSelected: _filterOpenNow,
                        onTap: () => setState(() => _filterOpenNow = !_filterOpenNow),
                      ),
                      const SizedBox(width: 8),

                      // Top Rated Toggle Pill
                      _buildFilterPill(
                        icon: Icons.star_rounded,
                        label: 'Top Rated ⭐ 4.0+',
                        isSelected: _filterTopRated,
                        onTap: () => setState(() => _filterTopRated = !_filterTopRated),
                      ),
                      const SizedBox(width: 8),

                      // Nearest (<3km) Pill
                      _buildFilterPill(
                        icon: Icons.near_me,
                        label: 'Near Me (< 3 km)',
                        isSelected: _filterNearestOnly,
                        onTap: () => setState(() => _filterNearestOnly = !_filterNearestOnly),
                      ),
                      const SizedBox(width: 8),

                      // Sort Pill
                      InkWell(
                        onTap: () {
                          setState(() {
                            _sortBy = _sortBy == 'distance' ? 'rating' : 'distance';
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _sortBy != 'distance'
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                size: 16,
                                color: _sortBy != 'distance' ? Colors.white : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _sortBy == 'rating' ? 'Sort: Top Rated' : 'Sort: Nearest First',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _sortBy != 'distance' ? Colors.white : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // === 5. LISTINGS HEADER WITH RESET ALL BUTTON ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        _getListingsSectionTitle(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      if (_activeFilterCount > 0)
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: const Text('Reset All', style: TextStyle(fontSize: 12, color: AppColors.error)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filteredShops.length} Found',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // === 6. BUSINESS LIST / EMPTY STATES ===
              if (shopState.isLoading)
                const SliverFillRemaining(
                  child: LoadingIndicator(message: 'Searching nearby shops, carts & services...'),
                )
              else if (filteredShops.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.storefront_outlined,
                    title: 'No shops or services found',
                    subtitle: 'Try clearing category or distance filter to view all listings',
                    buttonText: 'Show All Nearby Listings',
                    onButtonPressed: _clearAllFilters,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shop = filteredShops[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ShopCard(
                          shop: shop,
                          onTap: () => Navigator.pushNamed(context, '/shop-details', arguments: shop.id),
                        ),
                      ).animate().fadeIn(delay: (40 * index).ms).slideY(begin: 0.05);
                    },
                    childCount: filteredShops.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  String _getCategorySectionHeader() {
    switch (_selectedBusinessType) {
      case 'Shops & Retail':
        return 'SHOP CATEGORIES (Dukaan Types)';
      case 'Services & Repair':
        return 'SERVICE TYPES (Ghar Par Service)';
      case 'Street Carts & Stalls':
        return 'CART & STALL TYPES (Thela / Stall)';
      case 'Gyms & Fitness':
        return 'FITNESS & GYM TYPES';
      case 'Food & Dining':
        return 'FOOD & CAFES';
      default:
        return 'ALL LOCAL CATEGORIES';
    }
  }

  String _getListingsSectionTitle() {
    switch (_selectedBusinessType) {
      case 'Shops & Retail':
        return 'Shops Nearby';
      case 'Services & Repair':
        return 'Services Nearby';
      case 'Street Carts & Stalls':
        return 'Carts & Stalls Nearby';
      case 'Gyms & Fitness':
        return 'Gyms Nearby';
      case 'Food & Dining':
        return 'Food Places Nearby';
      default:
        return 'Nearby Listings';
    }
  }

  Widget _buildTypeTab(String label, String type) {
    final isSelected = _selectedBusinessType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _onSelectBusinessType(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dynamic Professional Filter Bottom Sheet ---
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Filter Options (Aasan Filter)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedBusinessType = 'All';
                            _selectedSubCategory = 'All';
                            _filterOpenNow = false;
                            _filterTopRated = false;
                            _filterNearestOnly = false;
                            _sortBy = 'distance';
                            _maxDistanceKm = 10.0;
                            _minRating = 0.0;
                          });
                          _clearAllFilters();
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppColors.error)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Business Mode
                  const Text('Select Business Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'All',
                      'Shops & Retail',
                      'Services & Repair',
                      'Street Carts & Stalls',
                      'Gyms & Fitness',
                      'Food & Dining'
                    ].map((type) {
                      final isSelected = _selectedBusinessType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (_) {
                          setModalState(() {
                            _selectedBusinessType = type;
                            _selectedSubCategory = _currentSubCategories.first;
                          });
                          _onSelectBusinessType(type);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 2. Maximum Distance / Radius
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Distance Range', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('${_maxDistanceKm.toStringAsFixed(1)} km Radius',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _maxDistanceKm,
                    min: 1.0,
                    max: 25.0,
                    divisions: 24,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => _maxDistanceKm = val),
                  ),
                  const SizedBox(height: 16),

                  // 3. Rating Threshold
                  const Text('Minimum Rating (Rating Chunien)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [0.0, 3.5, 4.0, 4.5].map((ratingVal) {
                      final isSelected = _minRating == ratingVal;
                      return ChoiceChip(
                        label: Text(ratingVal == 0.0 ? 'Any' : '$ratingVal+ ⭐'),
                        selected: isSelected,
                        onSelected: (_) => setModalState(() => _minRating = ratingVal),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 4. Quick Toggles
                  SwitchListTile(
                    title: const Text('Open Now Only (Abhi Khula Hai) 🟢'),
                    value: _filterOpenNow,
                    onChanged: (val) => setModalState(() => _filterOpenNow = val),
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

                  const SizedBox(height: 20),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Apply Filters / Filter Dekhein',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
