import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:split_wise/bottom_bar.dart';
import 'package:split_wise/login%20signup/splash_screen.dart';
import 'package:split_wise/login%20signup/welcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Initialize local notifications plugin globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Background handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    log('Background message received: ${message.notification!.title}');
    // FCM automatically shows notification in background/terminated states
  }
}

// Initialize FCM and local notifications
Future<void> initializeNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // Request permission
  await messaging.requestPermission();

  // Store FCM token
  String? token = await messaging.getToken();
  if (token != null && firebase_auth.FirebaseAuth.instance.currentUser != null) {
    String uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  // Handle token refresh
  messaging.onTokenRefresh.listen((newToken) {
    if (firebase_auth.FirebaseAuth.instance.currentUser != null) {
      String uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': newToken},
        SetOptions(merge: true),
      );
    }
  });

  // Initialize local notifications
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'No Title',
        message.notification!.body ?? 'No Body',
        message.data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }
  });

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle notification taps when app is opened from a terminated state
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    log('App opened from terminated state: ${initialMessage.notification?.title}');
    // Optionally navigate to NotificationScreen here
  }

  // Handle notification taps when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    log('App opened from background: ${message.notification?.title}');
    // Navigate to NotificationScreen if needed
  });
}

// Show local notification popup
Future<void> _showLocalNotification(String title, String body, String payload) async {
  const androidDetails = AndroidNotificationDetails(
    'settleup_channel',
    'Settle Up Notifications',
    channelDescription: 'Notifications for Settle Up app',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  const platformDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch % 100000,
    title,
    body,
    platformDetails,
    payload: payload,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await initializeNotifications();
    await Supabase.initialize(
      url: 'https://xzoyevujxvqaumrdskhd.supabase.co',
      anonKey: 'your-anon-key',
    );
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<firebase_auth.User?>(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const BottomBar(); // Logged-in users go to home
          } else {
            return const SplashScreen(); // Logged-out users go to welcome/login
          }
        },
      ),
    );
  }
}