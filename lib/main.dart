import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_wise/split/final_split_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:split_wise/Search/bottom_bar.dart';
import 'package:split_wise/Search/search_bar.dart';
import 'package:split_wise/friends.dart';
import 'package:split_wise/login_screen.dart';
import 'package:split_wise/sign_up.dart';
import 'package:split_wise/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase (only for storing images)
  await Supabase.initialize(
    url: 'https://your-project-id.supabase.co', // Replace with your Supabase project URL
    anonKey: 'your-anon-key', // Replace with your Supabase anon key
  );

  runApp(ProviderScope(child: MyApp()));
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
            return const BottomBar(); // User is logged in
          } else {
            return LoginPage(); // User is not logged in, show login page
          }
        },
      ),
    );
  }
}
