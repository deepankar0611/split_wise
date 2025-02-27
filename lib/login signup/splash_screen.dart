import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:split_wise/login%20signup/welcome.dart'; // Import Welcome Page
import 'package:split_wise/login%20signup/login_screen.dart'; // Import LoginPage
import 'package:split_wise/bottom_bar.dart'; // Import BottomBar
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:shared_preferences/shared_preferences.dart';

import 'login and signup.dart'; // Import Shared Preferences

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoFuture;

  @override
  void initState() {
    super.initState();

    // Initialize the video player controller
    Lottie.asset('assets/animation/Animation - 1740671879696.json',fit: BoxFit.contain);

    // Check user state and navigate after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _navigateBasedOnUserState();
    });
  }

  Future<void> _navigateBasedOnUserState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final User? user = FirebaseAuth.instance.currentUser;

    if (isFirstTime) {
      // First time user: Navigate to LoginPage and mark it as not first time
      await prefs.setBool('isFirstTime', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IntroPage()),
      );
    } else if (user != null && user.emailVerified) {
      // User is logged in and email is verified: Navigate to BottomBar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomBar()),
      );
    } else {
      // User has used the app but needs to sign in: Navigate to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF1A2E39),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.09,
            vertical: size.height * 0.20,
          ),
          child:Lottie.asset('assets/animation/Animation - 1740671879696.json',fit: BoxFit.contain),
        ),
      ),
    );
  }
}