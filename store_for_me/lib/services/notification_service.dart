import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling logic
  // Typically you don't need to do much here since FCM handles the notification itself
  // in the system tray when the app is in the background.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  static const AndroidNotificationChannel _customChannel = AndroidNotificationChannel(
    'high_importance_custom_sound', // id
    'Order & Urgent Alerts', // title
    description: 'This channel is used for orders with a custom zing sound.', // description
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('zing'),
    playSound: true,
  );

  Future<void> initialize() async {
    // 1. Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 2. Setup Android Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click when app is in foreground
        _handleNotificationClick(details.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_customChannel);

    // 3. Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data['screen'], // Example payload
        );
      }
    });

    // 5. Handle message which caused the app to open from terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data['screen']);
    }

    // 6. Listen to messages which caused the app to open from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data['screen']);
    });
  }

  void _handleNotificationClick(String? payload) {
    // This will be handled in main.dart or via a GlobalKey
    // For now, we print it. The actual navigation logic usually goes through a Navigator state.
    debugPrint("Notification clicked with payload: $payload");
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool useCustomSound = false,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      useCustomSound ? _customChannel.id : _channel.id,
      useCustomSound ? _customChannel.name : _channel.name,
      channelDescription: useCustomSound ? _customChannel.description : _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      sound: useCustomSound ? const RawResourceAndroidNotificationSound('zing') : null,
      playSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'zing.wav', // For iOS, usually Needs a wav file in bundle
      ),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
