import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:split_wise/bottom_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:split_wise/login%20signup/login_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background task '$task' started at ${DateTime.now()}");
    try {
      await Firebase.initializeApp();
      String? uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print("No user logged in, skipping notification check");
        return true;
      }

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'notification_channel',
        'Notifications',
        channelDescription: 'General notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      // Check friend requests
      QuerySnapshot friendRequests = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('friend_requests')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(minutes: 15)))
          .get();
      print("Found ${friendRequests.docs.length} new friend requests");
      for (var doc in friendRequests.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String senderUid = data['fromUid'];
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(senderUid).get();
        String senderName = (userDoc.data() as Map<String, dynamic>?)?['name'] ?? "Unknown";

        await flutterLocalNotificationsPlugin.show(
          doc.id.hashCode,
          "Friend Request",
          "$senderName sent a friend request",
          platformChannelSpecifics,
          payload: doc.id,
        );
      }

      // Check split reminders
      QuerySnapshot reminders = await FirebaseFirestore.instance
          .collectionGroup('reminders')
          .where('participants', arrayContains: uid)
          .where('sentBy', isNotEqualTo: uid)
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(minutes: 15)))
          .get();
      print("Found ${reminders.docs.length} new reminders");
      for (var doc in reminders.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String splitId = data['splitId'] ?? doc.reference.parent.parent!.id;
        String senderUid = data['sentBy'];
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(senderUid).get();
        String senderName = (userDoc.data() as Map<String, dynamic>?)?['name'] ?? "Unknown";
        DocumentSnapshot splitDoc = await FirebaseFirestore.instance.collection('splits').doc(splitId).get();
        String description = (splitDoc.data() as Map<String, dynamic>?)?['description'] ?? "No description";

        await flutterLocalNotificationsPlugin.show(
          doc.id.hashCode,
          "$senderName sent a reminder",
          "Split details of '$description'",
          platformChannelSpecifics,
          payload: splitId,
        );
      }

      print("Background task '$task' completed successfully");
      return true;
    } catch (e) {
      print("Background task '$task' failed: $e");
      return false;
    }
  });
}

// FCM initialization (kept for consistency, though not used for notifications)
void initializeFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  }

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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  initializeFCM();

  // Initialize Supabase for image storage
  await Supabase.initialize(
    url: 'https://xzoyevujxvqaumrdskhd.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6b3lldnVqeHZxYXVtcmRza2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyMTE1MjMsImV4cCI6MjA1NDc4NzUyM30.mbV_Scy2fXbMalxVRGHNKOxYx0o6t-nUPmDLlH5Mr_U',
  );

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );

  // Register periodic task
  await Workmanager().registerPeriodicTask(
    "notification_check",
    "checkNotifications",
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.connected, // Ensure internet is available
    ),
  );

  // Register one-off task on app start to check immediately
  await Workmanager().registerOneOffTask(
    "initial_notification_check",
    "checkNotifications",
    initialDelay: const Duration(seconds: 5),
  );

  runApp(const MyApp());
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
            return BottomBar();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}