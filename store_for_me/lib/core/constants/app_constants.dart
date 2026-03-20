class AppConstants {
  AppConstants._();

  // API — Change this IP when switching devices
  static const String _ip = '192.168.1.19';

  // static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator
  static const String baseUrl = 'http://$_ip:5000/api';
  static const String uploadsUrl = 'http://$_ip:5000';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Shop categories
  static const List<String> shopCategories = [
    'All',
    'Grocery',
    'Electronics',
    'Clothing',
    'Food & Restaurant',
    'Pharmacy',
    'Books & Stationery',
    'Hardware',
    'Beauty & Personal Care',
    'Sports',
    'Home & Furniture',
    'Other',
  ];

  // Category icons mapping
  static const Map<String, int> categoryIcons = {
    'All': 0xe148, // apps
    'Grocery': 0xe59c, // local_grocery_store
    'Electronics': 0xe1b1, // devices
    'Clothing': 0xf06e2, // checkroom
    'Food & Restaurant': 0xe56c, // restaurant
    'Pharmacy': 0xe548, // local_pharmacy
    'Books & Stationery': 0xe0ef, // menu_book
    'Hardware': 0xe1b1, // build
    'Beauty & Personal Care': 0xe590, // spa
    'Sports': 0xe58d, // sports_soccer
    'Home & Furniture': 0xe318, // home
    'Other': 0xe8b8, // more_horiz
  };
}
