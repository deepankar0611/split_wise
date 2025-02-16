import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_wise/Search/bottom_bar.dart';
import 'package:split_wise/Search/search_bar.dart';
import 'package:split_wise/friends.dart';
import 'package:split_wise/login_screen.dart'; // Ensure this file contains LoginPage class
import 'package:split_wise/sign_up.dart';
import 'package:split_wise/splash_screen.dart'; // Import the Splash Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const BottomBar(); // User is logged in
          } else {
            return  LoginPage(); // Ensure this class exists
          }
        },
      ),
    );
  }
}
