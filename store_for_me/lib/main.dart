import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/models/shop_model.dart';
import 'data/models/product_model.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/map_view_screen.dart';
import 'presentation/screens/shop_details_screen.dart';
import 'presentation/screens/product_details_screen.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/owner_dashboard_screen.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ShopRadarApp()));
}

class ShopRadarApp extends StatelessWidget {
  const ShopRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Radar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
            return _buildRoute(const HomeScreen(), settings);
          case '/map-view':
            return _buildRoute(const MapViewScreen(), settings);
          case '/shop-details':
            final shopId = settings.arguments as String;
            return _buildRoute(ShopDetailsScreen(shopId: shopId), settings);
          case '/product-details':
            final productId = settings.arguments as String;
            return _buildRoute(ProductDetailsScreen(productId: productId), settings);
          case '/cart':
            return _buildRoute(const CartScreen(), settings);
          case '/owner-dashboard':
            return _buildRoute(const OwnerDashboardScreen(), settings);
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
            final args = settings.arguments as Map<String, String>;
            return _buildRoute(ChatScreen(
              conversationId: args['conversationId']!,
              receiverId: args['receiverId']!,
              shopId: args['shopId']!,
              title: args['title'] ?? 'Chat',
            ), settings);
          case '/followed-shops':
            return _buildRoute(const FollowedShopsScreen(), settings);
          case '/shop-management':
            return _buildRoute(const ShopManagementScreen(), settings);
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
