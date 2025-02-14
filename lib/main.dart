import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:split_wise/get_started.dart';
import 'package:split_wise/login_screen.dart';
import 'package:split_wise/home_screen.dart';
import 'package:split_wise/welcome.dart';
import 'package:video_player/video_player.dart';
import 'package:split_wise/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Split Wise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

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
    _videoController =
        VideoPlayerController.asset('assets/animation/56qRH8Xl3ih8DWE25i.mp4');
    _initializeVideoFuture = _videoController.initialize();
    _videoController.setLooping(true); // Loop the video
    _videoController.play(); // Start playing the video

    // Navigate to the LoginPage after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IntroPage(), // Redirects to LoginPage
        ),
      );
    });
  }

  @override
  void dispose() {
    _videoController.dispose(); // Dispose of the controller to free resources
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
                // When the video is ready
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
                // Show a loading indicator or placeholder
                return Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300], // Placeholder background color
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
