import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:split_wise/Search/bottom_bar.dart';
import 'package:split_wise/Search/search_bar.dart';
import 'package:split_wise/friends.dart';
import 'package:split_wise/login_screen.dart'; // Ensure this file contains LoginPage class
import 'package:split_wise/sign_up.dart';
import 'package:split_wise/splash_screen.dart'; // Import the Splash Screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await supabase.Supabase.initialize(
    url: 'https://zadxcbkiiduplgjbnahl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphZHhjYmtpaWR1cGxnamJuYWhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk3MTIwODIsImV4cCI6MjA1NTI4ODA4Mn0.yS5WgYabLq7vY8JbdrNlr_cO6LtA02kJ6J_eyvVm878',
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
            return const BottomBar(); // User is logged in
          } else {
            return LoginPage(); // Ensure this class exists
          }
        },
      ),
    );
  }
}
