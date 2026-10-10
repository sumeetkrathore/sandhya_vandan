import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/sandesh.dart';
import '../screens/sandesh_detail_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/tipno_screen.dart';
import '../screens/programs_screen.dart';
import '../screens/wisdom_screen.dart';
import '../services/sandesh_service.dart';

class NotificationRouter {
  static final NotificationRouter _instance = NotificationRouter._internal();
  factory NotificationRouter() => _instance;
  NotificationRouter._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Map<String, dynamic>? _pendingPayload;
  bool _isAppReady = false;

  /// Called when MainNavigation has mounted and is ready to display screens
  void onAppReady() {
    _isAppReady = true;
    if (_pendingPayload != null) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      debugPrint(
        "NotificationRouter: App ready! Processing pending payload: $payload",
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handlePayload(payload);
      });
    }
  }

  /// Route from Firebase RemoteMessage (background click or cold-start)
  void routeFromRemoteMessage(RemoteMessage message) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    if (!data.containsKey('title') && message.notification?.title != null) {
      data['title'] = message.notification!.title;
    }
    if (!data.containsKey('body') && message.notification?.body != null) {
      data['body'] = message.notification!.body;
    }
    final img =
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl;
    if (!data.containsKey('image') && img != null) {
      data['image'] = img;
    }
    route(data);
  }

  /// Route from local notification payload string
  void routeFromLocalPayload(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) return;
    try {
      final decoded = jsonDecode(payloadStr);
      if (decoded is Map<String, dynamic>) {
        route(decoded);
      }
    } catch (e) {
      debugPrint("NotificationRouter: Failed to decode payload JSON: $e");
    }
  }

  /// Route a structured payload map
  void route(Map<String, dynamic> payload) {
    if (!_isAppReady) {
      debugPrint(
        "NotificationRouter: App not ready yet. Storing pending payload: $payload",
      );
      _pendingPayload = payload;
    } else {
      debugPrint("NotificationRouter: Routing payload immediately: $payload");
      handlePayload(payload);
    }
  }

  /// Main handler that parses the payload and navigates to the correct screen
  Future<void> handlePayload(Map<String, dynamic> data) async {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) {
      debugPrint(
        "NotificationRouter: Navigator context is null. Re-queuing payload.",
      );
      _pendingPayload = data;
      return;
    }

    try {
      final String type = (data['type'] ?? data['category'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final String title = (data['title'] ?? '').toString();
      final String body = (data['body'] ?? '').toString();
      final String url = (data['url'] ?? data['link'] ?? '').toString();

      final String titleLower = title.toLowerCase();
      final String bodyLower = body.toLowerCase();
      final String urlLower = url.toLowerCase();

      // 1. Sandhya Nem Daily Reminder
      if (type == 'nem') {
        Navigator.of(navContext).push(
          MaterialPageRoute(
            builder: (context) => const ReaderScreen(initialSectionIndex: 0),
          ),
        );
        return;
      }

      // 2. Tipno / Calendar Update
      if (type == 'tipno' ||
          type == 'calendar' ||
          titleLower.contains('tipno') ||
          titleLower.contains('calendar') ||
          titleLower.contains('panchang') ||
          bodyLower.contains('tipno') ||
          urlLower.contains('tipno')) {
        Navigator.of(navContext)
            .push(MaterialPageRoute(builder: (context) => const TipnoScreen()));
        return;
      }

      // 3. Events & Programs Update
      if (type == 'event' ||
          type == 'program' ||
          type == 'upcoming_programs' ||
          titleLower.contains('event') ||
          titleLower.contains('program') ||
          titleLower.contains('utsaw') ||
          titleLower.contains('utsav') ||
          titleLower.contains('mela') ||
          urlLower.contains('upcoming_programs')) {
        Navigator.of(
          navContext,
        ).push(MaterialPageRoute(builder: (context) => const ProgramsScreen()));
        return;
      }

      // 4. Video / Wisdom Update
      if (type == 'video' ||
          type == 'wisdom' ||
          type == 'youtube' ||
          titleLower.contains('video') ||
          titleLower.contains('satsang') ||
          titleLower.contains('gyan') ||
          urlLower.contains('youtube') ||
          urlLower.contains('youtu.be')) {
        Navigator.of(navContext).push(
          MaterialPageRoute(
            builder: (context) =>
                const WisdomScreen(initialTab: WisdomTab.videos),
          ),
        );
        return;
      }

      // 5. Audio / Bhajan Update
      if (type == 'audio' ||
          type == 'bhajan' ||
          type == 'kirtan' ||
          titleLower.contains('audio') ||
          titleLower.contains('bhajan') ||
          titleLower.contains('kirtan')) {
        Navigator.of(navContext).push(
          MaterialPageRoute(
            builder: (context) =>
                const WisdomScreen(initialTab: WisdomTab.audio),
          ),
        );
        return;
      }

      // 6. Default: Sandesh / Spiritual Message
      final postIdRaw = data['post_id'] ?? data['id'];
      final int? postId = postIdRaw != null
          ? int.tryParse(postIdRaw.toString())
          : null;
      final String? imageUrl =
          data['image']?.toString() ?? data['imageurl']?.toString();
      final String permalink = url;

      Sandesh? sandesh;
      if (title.isNotEmpty || body.isNotEmpty || postId != null) {
        sandesh = Sandesh(
          id: postId ?? 0,
          title: title.isNotEmpty ? title : "Daily Sandesh",
          content: body.isNotEmpty
              ? body
              : "Satguru Sandesh - Daily blessings from Satguru.",
          date: DateTime.now(),
          permalink: permalink,
          imageUrl: imageUrl,
        );
      } else {
        sandesh = await SandeshService().fetchLatestSandesh();
      }

      if (sandesh != null && navContext.mounted) {
        Navigator.of(navContext).push(
          MaterialPageRoute(
            builder: (context) => SandeshDetailScreen(sandesh: sandesh!),
          ),
        );
      }
    } catch (e, st) {
      debugPrint("NotificationRouter: Error executing route: $e\n$st");
    }
  }
}
