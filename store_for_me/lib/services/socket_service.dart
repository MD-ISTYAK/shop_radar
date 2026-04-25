import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/app_constants.dart';
import 'api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  io.Socket? _socket;
  bool _isConnected = false;
  final _messageController = StreamController<dynamic>.broadcast();
  final _statusController = StreamController<dynamic>.broadcast();
  final _userStatusController = StreamController<dynamic>.broadcast();
  final _notificationController = StreamController<dynamic>.broadcast();

  SocketService._internal();

  bool get isConnected => _isConnected;
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<dynamic> get statusStream => _statusController.stream;
  Stream<dynamic> get userStatusStream => _userStatusController.stream;
  Stream<dynamic> get notificationStream => _notificationController.stream;

  Future<void> connect() async {
    final token = await ApiService().getToken();
    if (token == null) return;

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    _socket = io.io(
      AppConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('🔌 Socket connected: ${AppConstants.wsUrl}');
      _isConnected = true;
      _registerListeners();
    });

    _socket!.onDisconnect((_) {
      print('🔌 Socket disconnected');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('🔌 Socket error: $error');
      _isConnected = false;
    });

    _socket!.connect();
  }

  void _registerListeners() {
    // Clear existing listeners to avoid duplicates on reconnect
    _socket?.off('message:new');
    _socket?.off('message:statusUpdate');
    _socket?.off('user:statusChange');
    _socket?.off('notification:new');

    _socket?.on('message:new', (data) {
      _messageController.add(data);
    });

    _socket?.on('message:statusUpdate', (data) {
      _statusController.add(data);
    });

    _socket?.on('user:statusChange', (data) {
      _userStatusController.add(data);
    });

    _socket?.on('notification:new', (data) {
      _notificationController.add(data);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // Helper methods to subscribe
  void onNewMessage(Function(dynamic) callback) => messageStream.listen(callback);
  void onMessageStatusUpdate(Function(dynamic) callback) => statusStream.listen(callback);
  void onUserStatusChange(Function(dynamic) callback) => userStatusStream.listen(callback);
  void onNotification(Function(dynamic) callback) => notificationStream.listen(callback);

  // Join methods
  void joinShopRoom(String shopId) => _socket?.emit('join:shop', shopId);
  void joinDeliveryRoom(String deliveryId) => _socket?.emit('join:delivery', deliveryId);

  // Emit methods
  void emitMessageReceived(String messageId, String senderId) {
    _socket?.emit('message:received', {'messageId': messageId, 'senderId': senderId});
  }

  void emitMessageSeen(String conversationId, String senderId) {
    _socket?.emit('message:seen', {'conversationId': conversationId, 'senderId': senderId});
  }

  void sendDeliveryLocation(String deliveryId, double lat, double lng) {
    _socket?.emit('delivery:location', {
      'deliveryId': deliveryId,
      'lat': lat,
      'lng': lng,
    });
  }

  // Other listeners
  void onQueueUpdate(Function(dynamic) callback) => _socket?.on('queue:update', callback);
  void onShopStatusUpdate(Function(dynamic) callback) => _socket?.on('shop:statusUpdate', callback);
  void onDeliveryLocationUpdate(Function(dynamic) callback) => _socket?.on('delivery:locationUpdate', callback);
  void onStreamStarted(Function(dynamic) callback) => _socket?.on('stream:started', callback);
  void onStreamComment(Function(dynamic) callback) => _socket?.on('stream:newComment', callback);
  void onStreamEnded(Function(dynamic) callback) => _socket?.on('stream:ended', callback);
  void onDeliveryNewRequest(Function(dynamic) callback) => _socket?.on('delivery:newRequest', callback);
  void onDeliveryClaimed(Function(dynamic) callback) => _socket?.on('delivery:claimed', callback);

  void offEvent(String event) => _socket?.off(event);
  void offAll() => _socket?.clearListeners();
}
