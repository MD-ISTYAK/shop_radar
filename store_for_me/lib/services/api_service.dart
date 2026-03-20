import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Auth
  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);

  Future<Response> getProfile() => _dio.get('/auth/profile');

  // Shops
  Future<Response> getNearbyShops({
    double? lat,
    double? lng,
    double? radius,
    String? category,
    String? search,
  }) {
    final params = <String, dynamic>{};
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    if (radius != null) params['radius'] = radius;
    if (category != null && category != 'All') params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    return _dio.get('/shops/nearby', queryParameters: params);
  }

  Future<Response> getShopById(String id) => _dio.get('/shops/$id');

  Future<Response> createShop(FormData data) =>
      _dio.post('/shops', data: data);

  Future<Response> updateShop(String id, FormData data) =>
      _dio.put('/shops/$id', data: data);

  Future<Response> toggleShopStatus(String id) =>
      _dio.patch('/shops/$id/toggle-status');

  Future<Response> updateShopStatus(String id, String status) =>
      _dio.patch('/shops/$id/status', data: {'status': status});

  Future<Response> updateCrowdLevel(String id, String crowdLevel) =>
      _dio.patch('/shops/$id/crowd', data: {'crowdLevel': crowdLevel});

  Future<Response> getOwnerShop() => _dio.get('/shops/owner/my-shop');

  // Products
  Future<Response> getProductsByShop(String shopId) =>
      _dio.get('/products/shop/$shopId');

  Future<Response> getProductById(String id) => _dio.get('/products/$id');

  Future<Response> addProduct(FormData data) =>
      _dio.post('/products', data: data);

  Future<Response> updateProduct(String id, FormData data) =>
      _dio.put('/products/$id', data: data);

  Future<Response> deleteProduct(String id) => _dio.delete('/products/$id');

  Future<Response> getOwnerProducts() => _dio.get('/products/owner/my-products');

  // Cart
  Future<Response> addToCart(Map<String, dynamic> data) =>
      _dio.post('/cart/add', data: data);

  Future<Response> getCart() => _dio.get('/cart');

  Future<Response> updateCartItem(Map<String, dynamic> data) =>
      _dio.put('/cart/update', data: data);

  Future<Response> removeFromCart(String productId) =>
      _dio.delete('/cart/remove/$productId');

  Future<Response> checkout(Map<String, dynamic> data) =>
      _dio.post('/cart/checkout', data: data);

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // ===================== SOCIAL =====================
  Future<Response> createPost(FormData data) =>
      _dio.post('/social/posts', data: data);

  Future<Response> getFeed({int page = 1, int limit = 20}) =>
      _dio.get('/social/feed', queryParameters: {'page': page, 'limit': limit});

  Future<Response> explorePosts({int page = 1, int limit = 20}) =>
      _dio.get('/social/explore', queryParameters: {'page': page, 'limit': limit});

  Future<Response> toggleLike(String postId) =>
      _dio.post('/social/posts/$postId/like');

  Future<Response> addComment(String postId, String text) =>
      _dio.post('/social/posts/$postId/comment', data: {'text': text});

  Future<Response> updatePost(String postId, String content) =>
      _dio.put('/social/posts/$postId', data: {'content': content});

  Future<Response> deletePost(String postId) =>
      _dio.delete('/social/posts/$postId');

  Future<Response> toggleHidePost(String postId) =>
      _dio.patch('/social/posts/$postId/hide');

  Future<Response> deleteComment(String postId, String commentId) =>
      _dio.delete('/social/posts/$postId/comments/$commentId');

  Future<Response> toggleHideComment(String postId, String commentId) =>
      _dio.patch('/social/posts/$postId/comments/$commentId/hide');

  Future<Response> getPostLikes(String postId) =>
      _dio.get('/social/posts/$postId/likes');

  Future<Response> getMyPosts() => _dio.get('/social/my-posts');

  Future<Response> createStory(FormData data) =>
      _dio.post('/social/stories', data: data);

  Future<Response> getStories() => _dio.get('/social/stories');

  Future<Response> getMyStories() => _dio.get('/social/my-stories');

  Future<Response> deleteStory(String storyId) =>
      _dio.delete('/social/stories/$storyId');

  Future<Response> toggleHideStory(String storyId) =>
      _dio.patch('/social/stories/$storyId/hide');

  Future<Response> getReels({int page = 1}) =>
      _dio.get('/social/reels', queryParameters: {'page': page});

  Future<Response> toggleFollow(String shopId) =>
      _dio.post('/social/follow/$shopId');

  Future<Response> checkFollow(String shopId) =>
      _dio.get('/social/follow/$shopId/check');

  Future<Response> getFollowersCount(String shopId) =>
      _dio.get('/social/follow/$shopId/count');

  // ===================== NOTIFICATIONS =====================
  Future<Response> getNotifications({int page = 1}) =>
      _dio.get('/notifications', queryParameters: {'page': page});

  Future<Response> markNotificationRead(String id) =>
      _dio.patch('/notifications/$id/read');

  Future<Response> markAllNotificationsRead() =>
      _dio.patch('/notifications/read-all');

  // ===================== QUEUE / TOKEN =====================
  Future<Response> takeQueueToken(String shopId) =>
      _dio.post('/tokens/take', data: {'shopId': shopId});

  Future<Response> getQueueStatus(String shopId) =>
      _dio.get('/tokens/shop/$shopId');

  Future<Response> getMyToken() => _dio.get('/tokens/my-token');

  Future<Response> advanceQueue(String shopId) =>
      _dio.post('/tokens/advance/$shopId');

  Future<Response> cancelQueueToken(String id) =>
      _dio.delete('/tokens/$id');

  // ===================== DELIVERY =====================
  Future<Response> createDeliveryRequest(Map<String, dynamic> data) =>
      _dio.post('/delivery', data: data);

  Future<Response> getMyDeliveryRequests() =>
      _dio.get('/delivery/my-requests');

  Future<Response> getShopDeliveryRequests() =>
      _dio.get('/delivery/shop-requests');

  Future<Response> updateDeliveryStatus(String id, String status) =>
      _dio.patch('/delivery/$id/status', data: {'status': status});

  // ===================== RECOMMENDATIONS =====================
  Future<Response> getRecommendations({double? lat, double? lng, String type = 'all'}) {
    final params = <String, dynamic>{'type': type};
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    return _dio.get('/recommendations', queryParameters: params);
  }

  // ===================== EMERGENCY =====================
  Future<Response> getEmergencyServices({String? type, double? lat, double? lng}) {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    return _dio.get('/emergency', queryParameters: params);
  }

  // ===================== SEARCH (Enhanced) =====================
  Future<Response> searchShops({
    String? query,
    String? category,
    double? lat,
    double? lng,
    double? radius,
    bool? openNow,
    double? minRating,
    String? sortBy,
  }) {
    final params = <String, dynamic>{};
    if (query != null && query.isNotEmpty) params['search'] = query;
    if (category != null && category != 'All') params['category'] = category;
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    if (radius != null) params['radius'] = radius;
    if (openNow == true) params['openNow'] = 'true';
    if (minRating != null) params['minRating'] = minRating;
    if (sortBy != null) params['sortBy'] = sortBy;
    return _dio.get('/shops/nearby', queryParameters: params);
  }

  // ===================== CHAT =====================
  Future<Response> sendChatMessage(String receiverId, String shopId, String text) =>
      _dio.post('/chat/send', data: {'receiverId': receiverId, 'shopId': shopId, 'text': text});

  Future<Response> getConversations() => _dio.get('/chat/conversations');

  Future<Response> getChatMessages(String conversationId, {int page = 1}) =>
      _dio.get('/chat/messages/$conversationId', queryParameters: {'page': page});

  Future<Response> startChatConversation(String shopId) =>
      _dio.post('/chat/start', data: {'shopId': shopId});

  // ===================== FOLLOWED SHOPS =====================
  Future<Response> getFollowedShops() =>
      _dio.get('/social/follow/my-follows');
}
