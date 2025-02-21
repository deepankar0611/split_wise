import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:split_wise/bottom_bar.dart';
import 'package:split_wise/setting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:split_wise/login%20signup/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase (only for storing images)
  await Supabase.initialize(
    url:
        'https://xzoyevujxvqaumrdskhd.supabase.co', // Replace with your Supabase project URL
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6b3lldnVqeHZxYXVtcmRza2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyMTE1MjMsImV4cCI6MjA1NDc4NzUyM30.mbV_Scy2fXbMalxVRGHNKOxYx0o6t-nUPmDLlH5Mr_U', // Replace with your Supabase anon key
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
            return  BottomBar(); // User is logged in
          } else {
            return LoginPage(); // User is not logged in, show login page
          }
        },
      ),
    );
  }
}
