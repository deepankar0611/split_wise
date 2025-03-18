import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:split_wise/login%20signup/splash_screen.dart'; // Adjust path
import 'package:split_wise/login%20signup/welcome.dart'; // Adjust path
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bottom_bar.dart';
import 'login signup/login_screen.dart';

// Initialize local notifications plugin globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Background handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    log('Background message received: ${message.notification!.title}');
  }
}

// Initialize FCM and local notifications
Future<void> initializeNotifications() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission();

  String? token = await messaging.getToken();
  if (token != null && firebase_auth.FirebaseAuth.instance.currentUser != null) {
    String uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  messaging.onTokenRefresh.listen((newToken) {
    if (firebase_auth.FirebaseAuth.instance.currentUser != null) {
      String uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': newToken},
        SetOptions(merge: true),
      );
    }
  });

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'No Title',
        message.notification!.body ?? 'No Body',
        message.data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    log('App opened from terminated state: ${initialMessage.notification?.title}');
  }

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    log('App opened from background: ${message.notification?.title}');
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
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6b3lldnVqeHZxYXVtcmRza2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyMTE1MjMsImV4cCI6MjA1NDc4NzUyM30.mbV_Scy2fXbMalxVRGHNKOxYx0o6t-nUPmDLlH5Mr_U', // Replace with your actual Supabase anon key
    );
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(
    DevicePreview(
      enabled: false,
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
            return SplashScreen();
          } else {
            return SplashScreen();
          }
        },
      ),
    );
  }
}