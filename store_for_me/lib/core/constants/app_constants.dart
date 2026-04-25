class AppConstants {
  AppConstants._();

  // API — Change this IP when switching devices ss
  static const String _ip = '192.168.1.9';
  static const bool useLocal = false; // Toggle this for local testing

  static const String baseUrl = useLocal
      ? 'http://$_ip:5000/api'
      : 'https://shop-radar-z0xe.onrender.com/api';

  static const String wsUrl = useLocal
      ? 'http://$_ip:5000'
      : 'https://shop-radar-z0xe.onrender.com';

  static const String uploadsUrl = useLocal
      ? 'http://$_ip:5000'
      : ''; // Cloudinary URLs are absolute

  /// Helper to get full image URL, handles both local and Cloudinary paths
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$uploadsUrl$path';
  }

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Google Maps API Key
  static const String googleMapsApiKey =
      'AIzaSyDzCAoTb1j3706Uf-3G2gI1CrJmiMJxd7s';

  // Razorpay Key
  static const String razorpayKey = 'rzp_test_your_key_here';

  // Agora App ID
  static const String agoraAppId = 'your_agora_app_id_here';

  // Shop categories (expanded)
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
    'Salon',
    'Clinic',
    'Repair',
    'Petrol Pump',
    'Mechanic',
    'Doctor',
    'Bakery',
    'Jewellery',
    'Pet Store',
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
    'Salon': 0xe590, // spa / content_cut
    'Clinic': 0xe548, // local_hospital
    'Repair': 0xe1b1, // build
    'Petrol Pump': 0xe531, // local_gas_station
    'Mechanic': 0xe1b1, // build
    'Doctor': 0xe548, // medical_services
    'Bakery': 0xe7a8, // cake
    'Jewellery': 0xe3ae, // diamond
    'Pet Store': 0xe91d, // pets
    'Other': 0xe8b8, // more_horiz
  };

  // User interests
  static const List<String> userInterests = [
    'Food',
    'Grocery',
    'Electronics',
    'Clothing',
    'Pharmacy',
    'Beauty',
    'Sports',
    'Books',
    'Hardware',
    'Home',
    'Medical',
    'Repair',
  ];

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'bn': 'Bengali',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'pa': 'Punjabi',
  };

  // Badge names and emoji
  static const Map<String, String> badgeEmoji = {
    'explorer': '🗺️',
    'foodie': '🍕',
    'saver': '💰',
    'trendsetter': '🔥',
    'super_shopper': '⭐',
    'shopradar_hero': '🏆',
    'first_review': '✍️',
    'social_butterfly': '🦋',
    'deal_hunter': '🎯',
    'loyal_customer': '❤️',
  };

  // Shop status colors
  static const Map<String, int> statusColors = {
    'open': 0xFF16A34A, // Green
    'busy': 0xFFF59E0B, // Orange
    'closed': 0xFF94A3B8, // Grey
    'temporarily_closed': 0xFFDC2626, // Red
  };
}
