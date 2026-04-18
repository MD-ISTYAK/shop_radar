import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/app_constants.dart';
import 'api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  io.Socket? _socket;
  bool _isConnected = false;

  SocketService._internal();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    final token = await ApiService().getToken();
    if (token == null) return;

    _socket = io.io(
      AppConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onError((error) {
      _isConnected = false;
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // Join a shop room (for queue updates, etc.)
  void joinShopRoom(String shopId) {
    _socket?.emit('join:shop', shopId);
  }

  // Join delivery tracking room
  void joinDeliveryRoom(String deliveryId) {
    _socket?.emit('join:delivery', deliveryId);
  }

  // Send delivery partner location
  void sendDeliveryLocation(String deliveryId, double lat, double lng) {
    _socket?.emit('delivery:location', {
      'deliveryId': deliveryId,
      'lat': lat,
      'lng': lng,
    });
  }

  // Advance queue (shop owner)
  void advanceQueue(String shopId, int currentToken, int totalWaiting) {
    _socket?.emit('queue:advance', {
      'shopId': shopId,
      'currentToken': currentToken,
      'totalWaiting': totalWaiting,
    });
  }

  // Update shop status
  void updateShopStatus(String shopId, String status, String crowdLevel) {
    _socket?.emit('shop:statusChange', {
      'shopId': shopId,
      'status': status,
      'crowdLevel': crowdLevel,
    });
  }

  // Live stream events
  void startStream(String shopId) {
    _socket?.emit('stream:start', {'shopId': shopId});
  }

  void sendStreamComment(String shopId, String text) {
    _socket?.emit('stream:comment', {'shopId': shopId, 'text': text});
  }

  void endStream(String shopId) {
    _socket?.emit('stream:end', {'shopId': shopId});
  }

  // Listen to events
  void onQueueUpdate(Function(dynamic) callback) {
    _socket?.on('queue:update', callback);
  }

  void onShopStatusUpdate(Function(dynamic) callback) {
    _socket?.on('shop:statusUpdate', callback);
  }

  void onDeliveryLocationUpdate(Function(dynamic) callback) {
    _socket?.on('delivery:locationUpdate', callback);
  }

  void onNotification(Function(dynamic) callback) {
    _socket?.on('notification:new', callback);
  }

  void onStreamStarted(Function(dynamic) callback) {
    _socket?.on('stream:started', callback);
  }

  void onStreamComment(Function(dynamic) callback) {
    _socket?.on('stream:newComment', callback);
  }

  void onStreamEnded(Function(dynamic) callback) {
    _socket?.on('stream:ended', callback);
  }

  // Remove listeners
  void offEvent(String event) {
    _socket?.off(event);
  }

  void offAll() {
    _socket?.clearListeners();
  }
}
