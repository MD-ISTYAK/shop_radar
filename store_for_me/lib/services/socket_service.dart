import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/app_constants.dart';
import 'api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;

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
    if (_isConnecting || (_socket != null && _socket!.connected)) {
       debugPrint('🔌 Socket already connecting or connected');
       return;
    }

    final token = await ApiService().getToken();
    if (token == null) {
      debugPrint('🔌 Socket connect failed: No token found');
      return;
    }

    _isConnecting = true;
    debugPrint('🔌 Attempting to connect to socket at ${AppConstants.wsUrl}');

    try {
      if (_socket != null) {
        _socket!.dispose();
      }

      _socket = io.io(
        AppConstants.wsUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Allow polling fallback
            .setAuth({'token': token})
            .setQuery({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('🔌 Socket Connected Successfully');
        _isConnected = true;
        _isConnecting = false;
        _registerListeners();
      });

      _socket!.onConnectError((data) {
        debugPrint('🔌 Socket Connect Error: $data');
        _isConnected = false;
        _isConnecting = false;
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 Socket Disconnected');
        _isConnected = false;
        _isConnecting = false;
      });

      _socket!.onReconnect((_) => debugPrint('🔌 Socket Reconnected'));
      _socket!.onReconnectAttempt((_) => debugPrint('🔌 Socket Reconnecting...'));

      _socket!.connect();
    } catch (e) {
      debugPrint('🔌 Socket Exception: $e');
      _isConnecting = false;
    }
  }

  void _registerListeners() {
    debugPrint('🔌 Registering Socket Listeners');
    // Clear existing to avoid duplicates
    _socket?.off('message:new');
    _socket?.off('message:statusUpdate');
    _socket?.off('user:statusChange');
    _socket?.off('notification:new');

    _socket?.on('message:new', (data) {
      debugPrint('📩 Socket: New Message Received');
      _messageController.add(data);
    });

    _socket?.on('message:statusUpdate', (data) {
      debugPrint('📩 Socket: Message Status Update');
      _statusController.add(data);
    });

    _socket?.on('user:statusChange', (data) {
      _userStatusController.add(data);
    });

    _socket?.on('notification:new', (data) {
      debugPrint('🔔 Socket: New Notification Received');
      _notificationController.add(data);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
  }

  // Helper methods to subscribe
  void onNewMessage(Function(dynamic) callback) => messageStream.listen(callback);
  void onMessageStatusUpdate(Function(dynamic) callback) => statusStream.listen(callback);
  void onUserStatusChange(Function(dynamic) callback) => userStatusStream.listen(callback);
  void onNotification(Function(dynamic) callback) => notificationStream.listen(callback);

  // Emit methods
  void joinShopRoom(String shopId) => _socket?.emit('join:shop', shopId);
  void joinDeliveryRoom(String deliveryId) => _socket?.emit('join:delivery', deliveryId);

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

  // Other listeners with direct socket access for legacy compatibility if needed
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

  /// Generic event listener for any socket event
  void onEvent(String event, Function(dynamic) callback) => _socket?.on(event, callback);
}
