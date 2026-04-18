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

  // ===================== AUTH =====================
  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);

  Future<Response> getProfile() => _dio.get('/auth/profile');

  // ===================== TOKEN MANAGEMENT =====================
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  // ===================== SHOPS =====================
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

  // ===================== PRODUCTS =====================
  Future<Response> getProductsByShop(String shopId) =>
      _dio.get('/products/shop/$shopId');

  Future<Response> getProductById(String id) => _dio.get('/products/$id');

  Future<Response> addProduct(FormData data) =>
      _dio.post('/products', data: data);

  Future<Response> updateProduct(String id, FormData data) =>
      _dio.put('/products/$id', data: data);

  Future<Response> deleteProduct(String id) => _dio.delete('/products/$id');

  Future<Response> getOwnerProducts() => _dio.get('/products/owner/my-products');

  // ===================== CART =====================
  Future<Response> addToCart(Map<String, dynamic> data) =>
      _dio.post('/cart/add', data: data);

  Future<Response> getCart() => _dio.get('/cart');

  Future<Response> updateCartItem(Map<String, dynamic> data) =>
      _dio.put('/cart/update', data: data);

  Future<Response> removeFromCart(String productId) =>
      _dio.delete('/cart/remove/$productId');

  Future<Response> checkout(Map<String, dynamic> data) =>
      _dio.post('/cart/checkout', data: data);

  // ===================== ORDERS =====================
  Future<Response> getMyOrders({String? status, int page = 1}) {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;
    return _dio.get('/orders/my-orders', queryParameters: params);
  }

  Future<Response> getOrderById(String id) => _dio.get('/orders/$id');

  Future<Response> getShopOrders({String? status, int page = 1}) {
    final params = <String, dynamic>{'page': page};
    if (status != null) params['status'] = status;
    return _dio.get('/orders/shop-orders', queryParameters: params);
  }

  Future<Response> updateOrderStatus(String id, String status) =>
      _dio.patch('/orders/$id/status', data: {'status': status});

  Future<Response> cancelOrder(String id, {String reason = ''}) =>
      _dio.patch('/orders/$id/cancel', data: {'reason': reason});

  Future<Response> getShopOrderStats() => _dio.get('/orders/shop-stats');

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

  Future<Response> getFollowedShops() =>
      _dio.get('/social/follow/my-follows');

  // ===================== REVIEWS =====================
  Future<Response> createReview(Map<String, dynamic> data) =>
      _dio.post('/reviews', data: data);

  Future<Response> getShopReviews(String shopId, {int page = 1}) =>
      _dio.get('/reviews/shop/$shopId', queryParameters: {'page': page});

  Future<Response> upvoteReview(String reviewId) =>
      _dio.post('/reviews/$reviewId/upvote');

  Future<Response> addOwnerReply(String reviewId, String text) =>
      _dio.post('/reviews/$reviewId/reply', data: {'text': text});

  Future<Response> deleteReview(String reviewId) =>
      _dio.delete('/reviews/$reviewId');

  // ===================== CHECK-INS =====================
  Future<Response> checkIn(Map<String, dynamic> data) =>
      _dio.post('/checkins', data: data);

  Future<Response> getShopCheckIns(String shopId) =>
      _dio.get('/checkins/shop/$shopId');

  Future<Response> getMyCheckIns({int page = 1}) =>
      _dio.get('/checkins/my-checkins', queryParameters: {'page': page});

  // ===================== DEALS =====================
  Future<Response> createDeal(Map<String, dynamic> data) =>
      _dio.post('/deals', data: data);

  Future<Response> getNearbyDeals({int page = 1}) =>
      _dio.get('/deals/nearby', queryParameters: {'page': page});

  Future<Response> getTrendingDeals() => _dio.get('/deals/trending');

  Future<Response> getMySavedDeals() => _dio.get('/deals/saved');

  Future<Response> getShopDeals(String shopId) =>
      _dio.get('/deals/shop/$shopId');

  Future<Response> toggleSaveDeal(String dealId) =>
      _dio.post('/deals/$dealId/save');

  Future<Response> deleteDeal(String dealId) =>
      _dio.delete('/deals/$dealId');

  // ===================== COMMUNITY Q&A =====================
  Future<Response> postQuestion(Map<String, dynamic> data) =>
      _dio.post('/community', data: data);

  Future<Response> getNearbyQuestions({int page = 1, String? tag}) {
    final params = <String, dynamic>{'page': page};
    if (tag != null) params['tag'] = tag;
    return _dio.get('/community', queryParameters: params);
  }

  Future<Response> getQuestion(String id) => _dio.get('/community/$id');

  Future<Response> answerQuestion(String questionId, Map<String, dynamic> data) =>
      _dio.post('/community/$questionId/answer', data: data);

  Future<Response> upvoteAnswer(String questionId, String answerId) =>
      _dio.post('/community/$questionId/answers/$answerId/upvote');

  // ===================== PRICE COMPARISON =====================
  Future<Response> compareProductPrice(String productName, {double? lat, double? lng, double? radius}) {
    final params = <String, dynamic>{'productName': productName};
    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    if (radius != null) params['radius'] = radius;
    return _dio.get('/prices/compare', queryParameters: params);
  }

  Future<Response> getPriceHistory(String productId, {int days = 30}) =>
      _dio.get('/prices/history/$productId', queryParameters: {'days': days});

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

  // ===================== DELIVERY PARTNER =====================
  Future<Response> registerAsDeliveryPartner(Map<String, dynamic> data) =>
      _dio.post('/delivery-partner/register', data: data);

  Future<Response> updatePartnerKYC(Map<String, dynamic> data) =>
      _dio.put('/delivery-partner/kyc', data: data);

  Future<Response> togglePartnerOnline({double? lat, double? lng}) =>
      _dio.post('/delivery-partner/toggle-online', data: {'lat': lat, 'lng': lng});

  Future<Response> updatePartnerLocation(double lat, double lng) =>
      _dio.post('/delivery-partner/update-location', data: {'lat': lat, 'lng': lng});

  Future<Response> getAvailableDeliveries() =>
      _dio.get('/delivery-partner/available');

  Future<Response> acceptDelivery(String deliveryId) =>
      _dio.post('/delivery-partner/accept/$deliveryId');

  Future<Response> completeDelivery(String deliveryId) =>
      _dio.post('/delivery-partner/complete/$deliveryId');

  Future<Response> getPartnerProfile() =>
      _dio.get('/delivery-partner/profile');

  Future<Response> getPartnerEarnings() =>
      _dio.get('/delivery-partner/earnings');

  // ===================== WALLET =====================
  Future<Response> getWallet() => _dio.get('/wallet');

  Future<Response> getWalletTransactions({int page = 1}) =>
      _dio.get('/wallet/transactions', queryParameters: {'page': page});

  Future<Response> addMoneyToWallet(double amount, String paymentId) =>
      _dio.post('/wallet/add-money', data: {'amount': amount, 'paymentId': paymentId});

  // ===================== REFERRALS =====================
  Future<Response> getMyReferrals() => _dio.get('/referrals/my-referrals');

  Future<Response> applyReferralCode(String code) =>
      _dio.post('/referrals/apply', data: {'referralCode': code});

  // ===================== GAMIFICATION =====================
  Future<Response> getMyBadges() => _dio.get('/gamification/badges');

  Future<Response> getLeaderboard() => _dio.get('/gamification/leaderboard');

  // ===================== AI =====================
  Future<Response> getShoppingAssistant(List<Map<String, String>> items, {double? lat, double? lng}) =>
      _dio.post('/ai/shopping-assistant', data: {'items': items, 'lat': lat, 'lng': lng});

  Future<Response> getCrowdPrediction(String shopId) =>
      _dio.get('/ai/crowd-prediction/$shopId');

  Future<Response> getBestTimeToVisit(String shopId) =>
      _dio.get('/ai/best-time/$shopId');

  Future<Response> getAlternativeShop(String shopId) =>
      _dio.get('/ai/alternative/$shopId');

  Future<Response> getBargainRange(String productName) =>
      _dio.get('/ai/bargain', queryParameters: {'productName': productName});

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

  // ===================== CHAT =====================
  Future<Response> sendChatMessage(String receiverId, String shopId, String text) =>
      _dio.post('/chat/send', data: {'receiverId': receiverId, 'shopId': shopId, 'text': text});

  Future<Response> getConversations() => _dio.get('/chat/conversations');

  Future<Response> getChatMessages(String conversationId, {int page = 1}) =>
      _dio.get('/chat/messages/$conversationId', queryParameters: {'page': page});

  Future<Response> startChatConversation(String shopId) =>
      _dio.post('/chat/start', data: {'shopId': shopId});
}
