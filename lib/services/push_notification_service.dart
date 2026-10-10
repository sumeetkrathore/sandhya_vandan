import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'notification_service.dart';
import 'notification_router.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if necessary here depending on how main.dart is setup
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission for push notifications
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Create high importance channel for background FCM messages to show banners
    final localAuth = NotificationService().notificationsPlugin;
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await localAuth
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidNotificationChannel sandeshChannel =
        AndroidNotificationChannel(
          'sandesh_push_channel',
          'Live Sandesh Updates',
          description: 'Real-time Sandesh notifications from jaisamadha.com',
          importance: Importance.max,
        );

    await localAuth
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(sandeshChannel);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 1. Check if app was opened from terminated state by tapping an FCM notification
    try {
      final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          "PushNotificationService: App opened from terminated state via FCM: ${initialMessage.data}",
        );
        NotificationRouter().routeFromRemoteMessage(initialMessage);
      }
    } catch (e) {
      debugPrint("Error reading initial FCM message: $e");
    }

    // 2. Handle when app is in background and user taps FCM notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        "PushNotificationService: FCM onMessageOpenedApp tapped: ${message.data}",
      );
      NotificationRouter().routeFromRemoteMessage(message);
    });

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      // Ignore stale messages older than 24 hours
      if (message.sentTime != null &&
          DateTime.now().difference(message.sentTime!).inHours > 24) {
        debugPrint(
          "PushNotificationService: Ignoring stale notification sent at ${message.sentTime}",
        );
        return;
      }

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotificationFromPush(message);
      }
    });

    // Optionally get the token for testing/targeting
    try {
      String? token = await _fcm.getToken();
      debugPrint("FCM Registration Token: $token");

      // Subscribe to topics so we can broadcast from WordPress easily
      await _fcm.subscribeToTopic('sandesh');
      await _fcm.subscribeToTopic('all');

      // PNFPB WordPress Plugin default topics
      await _fcm.subscribeToTopic('pnfpbgeneral');
      await _fcm.subscribeToTopic('pnfpbondemand');

      debugPrint("Subscribed to all push notification topics!");
    } catch (e) {
      debugPrint("Failed to get FCM token or subscribe to topic: $e");
    }
  }

  Future<void> _showLocalNotificationFromPush(RemoteMessage message) async {
    // Ignore stale push notifications older than 24 hours
    if (message.sentTime != null &&
        DateTime.now().difference(message.sentTime!).inHours > 24) {
      debugPrint(
        "PushNotificationService: Suppressing local pop-up for stale push message",
      );
      return;
    }

    // Show the notification using flutter_local_notifications to get BigTextStyle
    final localAuth = NotificationService().notificationsPlugin;

    final String type = (message.data['type'] ?? message.data['category'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    String title = message.notification?.title ?? '';
    if (title.trim().isEmpty) {
      if (type == 'tipno' || type == 'calendar') {
        title = "Dharmic Tipno Update";
      } else if (type == 'video' || type == 'wisdom') {
        title = "New Wisdom Video";
      } else if (type == 'event' || type == 'program') {
        title = "New Event & Program";
      } else if (type == 'audio' || type == 'bhajan') {
        title = "New Audio Release";
      } else {
        final dateStr = DateFormat('MMM d').format(DateTime.now());
        title = "Today's Sandesh ($dateStr)";
      }
    }
    String body = message.notification?.body ?? '';

    if (body.isEmpty) {
      if (type == 'tipno' ||
          title.contains('Tipno') ||
          title.contains('Calendar')) {
        body = 'Tap to view the updated Dharmic Tipno calendar.';
      } else if (type == 'audio' ||
          title.contains('Audio') ||
          title.contains('Bhajan')) {
        body = 'Tap to listen to the new Audio release.';
      } else if (type == 'video' ||
          title.contains('Video') ||
          title.contains('Gyan')) {
        body = 'Tap to watch the latest discourse.';
      } else if (type == 'event' ||
          title.contains('Event') ||
          title.contains('Program')) {
        body = 'Tap to view event details.';
      } else {
        body = 'Tap to view the latest update.';
      }
    }

    // Check for image in data payload or notification payload
    String? imageUrl =
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl;
    if (imageUrl == null && message.data.containsKey('image')) {
      imageUrl = message.data['image'];
    }
    if (imageUrl == null && message.data.containsKey('imageurl')) {
      imageUrl = message.data['imageurl'];
    }

    StyleInformation styleInformation = BigTextStyleInformation(
      body,
      contentTitle: title,
    );

    AndroidBitmap<Object> largeIconBitmap = const DrawableResourceAndroidBitmap(
      '@mipmap/ic_launcher',
    );
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final imageBitmap = ByteArrayAndroidBitmap(response.bodyBytes);
          largeIconBitmap =
              imageBitmap; // Use the image for the right-side banner icon

          styleInformation = BigPictureStyleInformation(
            imageBitmap,
            largeIcon: null, // Hide the large icon when the picture is fully expanded (standard practice)
            contentTitle: title,
            summaryText: body,
            htmlFormatContent: true,
            htmlFormatContentTitle: true,
          );
        }
      } catch (e) {
        debugPrint("Failed to download image for push notification: $e");
      }
    }

    String actionLabel = 'Tap to read';
    if (type == 'tipno' ||
        title.contains('Tipno') ||
        title.contains('Calendar')) {
      actionLabel = 'Tap to view calendar';
    } else if (type == 'audio' ||
        title.contains('Audio') ||
        body.startsWith('Audio')) {
      actionLabel = 'Tap to listen';
    } else if (type == 'video' ||
        title.contains('Video') ||
        body.startsWith('Video')) {
      actionLabel = 'Tap to watch';
    } else if (type == 'event' ||
        title.contains('Event') ||
        body.startsWith('Event')) {
      actionLabel = 'Tap to view';
    }

    final Map<String, dynamic> payloadMap = Map<String, dynamic>.from(
      message.data,
    );
    if (!payloadMap.containsKey('title') && title.isNotEmpty) {
      payloadMap['title'] = title;
    }
    if (!payloadMap.containsKey('body') && body.isNotEmpty) {
      payloadMap['body'] = body;
    }
    if (imageUrl != null && !payloadMap.containsKey('image')) {
      payloadMap['image'] = imageUrl;
    }

    final bool isSandesh =
        type == 'sandesh' ||
        (!type.contains('event') &&
            !type.contains('program') &&
            !type.contains('tipno') &&
            !type.contains('video') &&
            !type.contains('audio') &&
            (title.contains('Sandesh') || body.contains('Sandesh')));

    localAuth.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isSandesh ? 'sandesh_push_channel' : 'high_importance_channel',
          isSandesh ? 'Live Sandesh Updates' : 'High Importance Notifications',
          channelDescription: isSandesh
              ? 'Real-time Sandesh notifications from jaisamadha.com'
              : 'Important announcements and updates',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: largeIconBitmap,
          styleInformation: styleInformation,
          actions: [
            AndroidNotificationAction(
              'open_action',
              actionLabel,
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payloadMap),
    );
  }
}
