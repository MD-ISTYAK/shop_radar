import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/models/shop_model.dart';
import 'data/models/product_model.dart';
import 'data/models/order_model.dart';
import 'data/models/chat_models.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/discover_screen.dart';
import 'presentation/screens/orders_screen.dart';
import 'presentation/screens/social_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/map_view_screen.dart';
import 'presentation/screens/shop_details_screen.dart';
import 'presentation/screens/product_details_screen.dart';
import 'presentation/screens/order_details_screen.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/owner_shell.dart';
import 'presentation/screens/owner_orders_screen.dart';
import 'presentation/screens/owner_order_details_screen.dart';
import 'presentation/screens/add_shop_screen.dart';
import 'presentation/screens/add_product_screen.dart';
import 'presentation/screens/manage_products_screen.dart';
import 'presentation/screens/feed_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/queue_screen.dart';
import 'presentation/screens/emergency_screen.dart';
import 'presentation/screens/create_post_screen.dart';
import 'presentation/screens/create_story_screen.dart';
import 'presentation/screens/chat_list_screen.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/followed_shops_screen.dart';
import 'presentation/screens/shop_management_screen.dart';
import 'presentation/screens/wallet_screen.dart';
import 'presentation/screens/badges_screen.dart';
import 'presentation/screens/deals_screen.dart';
import 'presentation/screens/delivery_partner_screen.dart';
import 'presentation/screens/ai_assistant_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/referral_screen.dart';
import 'presentation/screens/order_scanner_screen.dart';
import 'presentation/screens/kyc_upload_screen.dart';
import 'presentation/screens/delivery_order_details_screen.dart';
import 'presentation/screens/subscription_screen.dart';
// P2P Sharing - temporarily disabled
// import 'features/sharing/presentation/screens/sharing_home_screen.dart';
// import 'features/sharing/presentation/screens/device_discovery_screen.dart';
// import 'features/sharing/presentation/screens/file_selector_screen.dart';
// import 'features/sharing/presentation/screens/file_transfer_screen.dart';
// import 'features/sharing/presentation/screens/receive_screen.dart';
import 'dart:io';
import 'presentation/screens/reels_screen.dart';
import 'presentation/screens/edit_profile_screen.dart';
import 'presentation/screens/start_business_screen.dart';
import 'presentation/screens/my_businesses_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'presentation/screens/magico_files_screen.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/snap_camera_screen.dart';
import 'services/app_lifecycle_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and Notifications
  await FirebaseService.initialize();
  await NotificationService().initialize();
  
  // Register lifecycle observer for video cache cleanup
  AppLifecycleManager().register();
  
  runApp(const ProviderScope(child: ShopRadarApp()));
}

class ShopRadarApp extends ConsumerWidget {
  const ShopRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Shop Radar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _buildRoute(const SplashScreen(), settings);
          case '/login':
            return _buildRoute(const LoginScreen(), settings);
          case '/register':
            return _buildRoute(const RegisterScreen(), settings);
          case '/home':
            return _buildRoute(const MainShell(), settings);
          case '/discover':
            return _buildRoute(const DiscoverScreen(), settings);
          case '/orders':
            return _buildRoute(const OrdersScreen(), settings);
          case '/social':
            return _buildRoute(const SocialScreen(), settings);
          case '/profile':
            return _buildRoute(const ProfileScreen(), settings);
          case '/map-view':
            return _buildRoute(const MapViewScreen(), settings);
          case '/shop-details':
            final shopId = settings.arguments as String;
            return _buildRoute(ShopDetailsScreen(shopId: shopId), settings);
          case '/product-details':
            final productId = settings.arguments as String;
            return _buildRoute(ProductDetailsScreen(productId: productId), settings);
          case '/order-details':
            final order = settings.arguments as OrderModel;
            return _buildRoute(OrderDetailsScreen(order: order), settings);
          case '/cart':
            return _buildRoute(const CartScreen(), settings);
          case '/owner-dashboard':
            return _buildRoute(const OwnerShell(), settings);
          case '/owner-orders':
            return _buildRoute(const OwnerOrdersScreen(), settings);
          case '/owner-order-details':
            final order = settings.arguments as OrderModel;
            return _buildRoute(OwnerOrderDetailsScreen(order: order), settings);
          case '/add-shop':
            final shopArg = settings.arguments as ShopModel?;
            return _buildRoute(AddShopScreen(existingShop: shopArg), settings);
          case '/add-product':
            final productArg = settings.arguments as ProductModel?;
            return _buildRoute(AddProductScreen(existingProduct: productArg), settings);
          case '/manage-products':
            return _buildRoute(const ManageProductsScreen(), settings);
          case '/feed':
            return _buildRoute(const FeedScreen(), settings);
          case '/notifications':
            return _buildRoute(const NotificationsScreen(), settings);
          case '/queue':
            final args = settings.arguments as Map<String, String>;
            return _buildRoute(QueueScreen(shopId: args['shopId']!, shopName: args['shopName'] ?? ''), settings);
          case '/emergency':
            return _buildRoute(const EmergencyScreen(), settings);
          case '/create-post':
            return _buildRoute(const CreatePostScreen(), settings);
          case '/create-story':
            return _buildRoute(const CreateStoryScreen(), settings);
          case '/chat-list':
            return _buildRoute(const ChatListScreen(), settings);
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            return _buildRoute(ChatScreen(
              conversationId: args['conversationId']!,
              receiverId: args['receiverId']!,
              shopId: args['shopId']!,
              title: args['title'] ?? 'Chat',
              otherUser: args['otherUser'] as ChatUserModel?,
            ), settings);
          case '/followed-shops':
            return _buildRoute(const FollowedShopsScreen(), settings);
          case '/shop-management':
            return _buildRoute(const ShopManagementScreen(), settings);
          case '/wallet':
            return _buildRoute(const WalletScreen(), settings);
          case '/badges':
            return _buildRoute(const BadgesScreen(), settings);
          case '/deals':
            return _buildRoute(const DealsScreen(), settings);
          case '/delivery-partner':
            return _buildRoute(const DeliveryPartnerScreen(), settings);
          case '/delivery-partner/kyc':
            return _buildRoute(const KYCUploadScreen(), settings);
          case '/ai-assistant':
            return _buildRoute(const AIAssistantScreen(), settings);
          case '/settings':
            return _buildRoute(const SettingsScreen(), settings);
          case '/referral':
            return _buildRoute(const ReferralScreen(), settings);
          case '/subscription':
            return _buildRoute(const SubscriptionScreen(), settings);
          case '/order-scanner':
            return _buildRoute(const OrderScannerScreen(), settings);
          case '/delivery-order-details':
            final delivery = settings.arguments as Map<String, dynamic>;
            return _buildRoute(DeliveryOrderDetailsScreen(delivery: delivery), settings);
          // P2P Sharing routes - temporarily disabled
          // case '/sharing':
          //   return _buildRoute(const SharingHomeScreen(), settings);
          // case '/sharing/discovery':
          //   return _buildRoute(const DeviceDiscoveryScreen(), settings);
          // case '/sharing/selector':
          //   final args = settings.arguments as Map<String, dynamic>;
          //   return _buildRoute(FileSelectorScreen(
          //     targetDevice: args['device'],
          //     myName: args['myName'],
          //   ), settings);
          // case '/sharing/transfer':
          //   final args = settings.arguments as Map<String, dynamic>?;
          //   return _buildRoute(FileTransferScreen(
          //     device: args?['device'],
          //     files: args?['files'],
          //     myName: args?['myName'],
          //   ), settings);
          // case '/sharing/receive':
          //   return _buildRoute(const ReceiveScreen(), settings);
          case '/reels':
            return _buildRoute(const ReelsScreen(), settings);
          case '/edit-profile':
            return _buildRoute(const EditProfileScreen(), settings);
          case '/start-business':
            return _buildRoute(const StartBusinessScreen(), settings);
          case '/my-businesses':
            return _buildRoute(const MyBusinessesScreen(), settings);
          case '/snap-camera':
            return _buildRoute(const SnapCameraScreen(), settings);
          case '/magico/files':
            return _buildRoute(const MagicoFilesScreen(), settings);
          default:
            return _buildRoute(const SplashScreen(), settings);
        }
      },
    );
  }

  MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
