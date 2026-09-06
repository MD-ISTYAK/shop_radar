class AppConstants {
  AppConstants._();

  // Environment & Configuration variables (can be overridden with --dart-define)
  static const String _ip =
      String.fromEnvironment('API_IP', defaultValue: '192.168.1.69');
  static const bool useLocal =
      bool.fromEnvironment('USE_LOCAL', defaultValue: true);

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: useLocal
        ? 'http://$_ip:5000/api'
        : 'https://shop-radar-z0xe.onrender.com/api',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: useLocal
        ? 'http://$_ip:5000'
        : 'https://shop-radar-z0xe.onrender.com',
  );

  static const String uploadsUrl = String.fromEnvironment(
    'UPLOADS_URL',
    defaultValue: useLocal
        ? 'http://$_ip:5000'
        : '', // Cloudinary URLs are absolute
  );

  /// Helper to get full image URL, handles both local and Cloudinary paths
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$uploadsUrl$path';
  }

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Google Maps API Key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDzCAoTb1j3706Uf-3G2gI1CrJmiMJxd7s',
  );

  // Razorpay Key
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: 'rzp_test_SkCbaMDux0GpYx',
  );

  // Agora App ID
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );

  // Business & Service Types
  static const List<String> businessTypes = [
    'All',
    'Shops & Retail',
    'Services & Repair',
    'Street Carts & Stalls',
    'Gyms & Fitness',
    'Food & Dining',
  ];

  // Dynamic Sub-Categories for simple Indian user navigation
  static const Map<String, List<String>> subCategoriesByBusinessType = {
    'All': [
      'All',
      'Grocery',
      'AC & Appliance Repair',
      'Plumbing & Electrician',
      'Street Carts & Tea Stalls',
      'Gyms & Fitness',
      'Salons & Beauty',
      'Clinics & Medical',
      'Food & Restaurant',
      'Automobile & Mechanic',
      'Home Services',
      'Electronics',
      'Clothing',
      'Pharmacy',
      'Hardware',
      'Bakery',
      'Other',
    ],
    'Shops & Retail': [
      'All Shops',
      'Kirana & Grocery',
      'Electronics & Mobile',
      'Clothing & Fashion',
      'Pharmacy & Medical',
      'Hardware & Tools',
      'Bakery & Sweets',
      'Books & Stationery',
      'Jewellery',
    ],
    'Services & Repair': [
      'All Services',
      'AC & Fridge Repair',
      'Plumbing & Electrician',
      'Motorcycle & Car Mechanic',
      'Home Cleaning & Service',
      'Salons & Beauty Care',
      'Doctor & Clinic Visit',
    ],
    'Street Carts & Stalls': [
      'All Carts & Stalls',
      'Tea & Coffee Stall',
      'Vegetable & Fruit Cart',
      'Chaat & Street Food',
      'Juice & Coconut Cart',
      'Fast Food & Snacks',
    ],
    'Gyms & Fitness': [
      'All Fitness',
      'Gym & Weights',
      'Yoga & Meditation',
      'Zumba & Fitness Studio',
    ],
    'Food & Dining': [
      'All Food',
      'Restaurants & Dhabas',
      'Fast Food & Pizza',
      'Sweets & Bakery',
      'Cafes & Juice Bar',
    ],
  };

  // Shop & Service categories (expanded for all local businesses)
  static const List<String> shopCategories = [
    'All',
    'Grocery',
    'AC & Appliance Repair',
    'Plumbing & Electrician',
    'Street Carts & Tea Stalls',
    'Gyms & Fitness',
    'Salons & Beauty',
    'Clinics & Medical',
    'Food & Restaurant',
    'Automobile & Mechanic',
    'Home Services',
    'Electronics',
    'Clothing',
    'Pharmacy',
    'Books & Stationery',
    'Hardware',
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
    'hi': 'हिंदी (Hindi)',
    'bn': 'বাংলা (Bengali)',
    'mr': 'मराठी (Marathi)',
    'te': 'తెలుగు (Telugu)',
    'ta': 'தமிழ் (Tamil)',
    'gu': 'ગુજરાતી (Gujarati)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'ml': 'മലയാളം (Malayalam)',
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
