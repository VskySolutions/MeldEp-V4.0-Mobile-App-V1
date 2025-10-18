// lib/services/notification_services.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Safely load a Flutter asset for use as Android big/large icon; null if absent.
Future<AndroidBitmap<Object>?> _safeAssetBitmap(String path) async {
  try {
    final bytes = await rootBundle.load(path);
    return ByteArrayAndroidBitmap(bytes.buffer.asUint8List());
  } catch (e) {
    debugPrint('Large icon load failed: $e');
    return null;
  }
}

// Retry helper for transient getToken failures (SERVICE_NOT_AVAILABLE, network hiccups).
Future<String?> _getFcmTokenWithRetry(FirebaseMessaging messaging,
    {int maxAttempts = 5}) async {
  int attempt = 0;
  while (attempt < maxAttempts) {
    try {
      final t = await messaging.getToken();
      if (t != null && t.isNotEmpty) return t;
    } catch (e) {
      debugPrint('getToken failed (attempt ${attempt + 1}): $e');
    }
    final delayMs = (math.pow(2, attempt) as num).toInt() * 1000; // 1s,2s,4s,8s,16s
    await Future.delayed(Duration(milliseconds: delayMs));
    attempt++;
  }
  return null;
}

/// Background FCM handler (separate isolate).
/// Only show a local notification for data-only messages with non-empty title/body to avoid duplicates and blanks.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // If the message carries a notification payload, Android will render it in background—do not duplicate.
  if (message.notification != null) return;

  // Avoid blank notifications.
  final dataTitle = message.data['title']?.toString().trim();
  final dataBody  = message.data['body']?.toString().trim();
  if ((dataTitle?.isEmpty ?? true) && (dataBody?.isEmpty ?? true)) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const init = InitializationSettings(
    android: AndroidInitializationSettings('ic_stat_notify'), // drawable small icon must exist
    iOS: DarwinInitializationSettings(),
    macOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(init);

  const channel = AndroidNotificationChannel(
    'meld_default',
    'General Notifications',
    description: 'Default channel for app notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Big picture for expanded layout if asset is available; otherwise show a normal notification.
  final bigIcon = await _safeAssetBitmap('assets/icon/vskyLogo.png');
  final style = bigIcon == null
      ? null
      : BigPictureStyleInformation(
          bigIcon,            // expanded image
          largeIcon: bigIcon, // collapsed logo
        );

  final android = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    icon: 'ic_stat_notify',
    styleInformation: style,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.message,
    playSound: true,
  );

  final id = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF;
  await plugin.show(
    id,
    dataTitle,
    dataBody,
    NotificationDetails(android: android),
    payload: message.data.toString(),
  );
}

class NotificationServices {
  NotificationServices._();
  static final NotificationServices instance = NotificationServices._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'meld_default',
    'General Notifications',
    description: 'Default channel for app notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _inited = false;

  /// Call once after Firebase.initializeApp and after registering the background handler in main.
  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    // Enable token generation; Android won’t auto-show in foreground so we will.
    await _messaging.setAutoInitEnabled(true);

    // Local notifications init (requires a real drawable small icon named ic_stat_notify).
    const init = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notify'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _fln.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('Notification tapped payload=${resp.payload}');
      },
    );

    // Pre-create channel so system/our code uses consistent, high-importance settings.
    await _fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Get token with retry; don’t crash on failure, keep listening to onTokenRefresh.
    final token = await _getFcmTokenWithRetry(_messaging);
    if (token != null && token.isNotEmpty) {
      debugPrint('FCM TOKEN: $token');
    } else {
      debugPrint('FCM TOKEN: unavailable after retries (will log on refresh)');
    }
    _messaging.onTokenRefresh.listen((t) => debugPrint('FCM TOKEN (refreshed): $t'));

    // Foreground: always show a local notification so banners appear in-app.
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      final title = msg.notification?.title ?? (msg.data['title']?.toString() ?? 'Notification');
      final body  = msg.notification?.body  ?? (msg.data['body']?.toString()  ?? '');

      final bigIcon = await _safeAssetBitmap('assets/icon/vskyLogo.png');
      final style = bigIcon == null
          ? null
          : BigPictureStyleInformation(
              bigIcon,            // expanded image
              largeIcon: bigIcon, // collapsed logo
            );

      final android = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        icon: 'ic_stat_notify',
        styleInformation: style,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        playSound: true,
      );

      await _fln.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: android),
        payload: msg.data.toString(),
      );
    });

    // Optional deep-link handling.
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Notification opened from background: ${msg.data}');
    });
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('Notification opened from terminated: ${initial.data}');
    }
  }
}
