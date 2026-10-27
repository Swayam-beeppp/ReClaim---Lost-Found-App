import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:khuje_pai/firebase_options.dart';

const String kPushChannelId = "reclaim_alerts";

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static String? _currentCollegeTopic;
  static String? _currentUserTopic;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _requestPermissions();
    await _setForegroundOptions();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((_) {});

    await _syncUserTopics();
    _listenAuthChanges();
    _listenTokenRefresh();

    _initialized = true;
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      kPushChannelId,
      "ReClaim Alerts",
      description: "Alerts for new found-item posts and lost-item requests.",
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _setForegroundOptions() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

    await _local.show(
      notification.hashCode,
      notification.title ?? "ReClaim",
      notification.body ?? "",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          kPushChannelId,
          "ReClaim Alerts",
          channelDescription:
              "Alerts for new found-item posts and lost-item requests.",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static void _listenAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((_) async {
      await _syncUserTopics();
    });
  }

  static void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((_) async {
      await _syncUserTopics();
    });
  }

  static Future<void> _syncUserTopics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _clearTopics();
        return;
      }

      final uid = user.uid;
      final userTopic = "user_$uid";
      await _ensureSubscribedToUserTopic(userTopic);

      final userDoc =
          await FirebaseFirestore.instance.collection("User").doc(uid).get();
      final code = (userDoc.data()?["collegeCode"] ?? "").toString().trim();
      if (code.isNotEmpty) {
        final collegeTopic = "college_$code";
        await _ensureSubscribedToCollegeTopic(collegeTopic);
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection("User").doc(uid).set({
          "fcmTokens": FieldValue.arrayUnion([token]),
          "lastFcmTokenAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Swallow permission/network errors to avoid crashing the app
    }
  }

  static Future<void> _ensureSubscribedToCollegeTopic(String next) async {
    if (_currentCollegeTopic == next) return;
    if (_currentCollegeTopic != null) {
      await _messaging.unsubscribeFromTopic(_currentCollegeTopic!);
    }
    await _messaging.subscribeToTopic(next);
    _currentCollegeTopic = next;
  }

  static Future<void> _ensureSubscribedToUserTopic(String next) async {
    if (_currentUserTopic == next) return;
    if (_currentUserTopic != null) {
      await _messaging.unsubscribeFromTopic(_currentUserTopic!);
    }
    await _messaging.subscribeToTopic(next);
    _currentUserTopic = next;
  }

  static Future<void> _clearTopics() async {
    if (_currentCollegeTopic != null) {
      await _messaging.unsubscribeFromTopic(_currentCollegeTopic!);
      _currentCollegeTopic = null;
    }
    if (_currentUserTopic != null) {
      await _messaging.unsubscribeFromTopic(_currentUserTopic!);
      _currentUserTopic = null;
    }
  }

  static Future<void> refreshUserTopics() async {
    await _syncUserTopics();
  }
}
