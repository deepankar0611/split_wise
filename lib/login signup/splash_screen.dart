import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_wise/bottom_bar.dart';
import 'package:split_wise/login%20signup/welcome.dart';
import 'package:video_player/video_player.dart';

import '../Helper/checkforupdate.dart';
import 'login_screen.dart';

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
      checkForUpdate();
    // Initialize the video player controller
    _videoController = VideoPlayerController.asset('assets/animation/56qRH8Xl3ih8DWE25i.mp4');
    _initializeVideoFuture = _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.play();

    // Navigate after delay, but only if mounted
    _navigateBasedOnUserState();
  }

  Future<void> _navigateBasedOnUserState() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final User? user = FirebaseAuth.instance.currentUser;
    await Future.delayed(const Duration(seconds: 2));

    // Check if the widget is still mounted before navigating
    if (!mounted) return;

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
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.09,
            vertical: size.height * 0.20,
          ),
          child: FutureBuilder(
            future: _initializeVideoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayer(_videoController),
                  ),
                );
              } else {
                return Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}