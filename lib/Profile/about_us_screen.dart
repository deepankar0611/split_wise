import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart'; // For SVG icons

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Function to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00897B), // Teal (starting point)
              Color(0xFF004D40), // Darker teal for depth
              Color(0xFF1A3C6D), // Deep blue (ties to Profile screen)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context, screenWidth),
                SizedBox(height: screenHeight * 0.03),
                _buildHeader(screenWidth),
                SizedBox(height: screenHeight * 0.02),
                _buildDescription(screenWidth),
                SizedBox(height: screenHeight * 0.04),
                _buildTeamSection(screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.03),
                _buildContactSection(screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: screenWidth * 0.06),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          "About Us",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        SizedBox(width: screenWidth * 0.06), // Spacer for symmetry
      ],
    );
  }

  Widget _buildHeader(double screenWidth) {
    return FadeInDown(
      duration: Duration(milliseconds: 600),
      child: Text(
        "Split Up",
        style: GoogleFonts.poppins(
          fontSize: screenWidth * 0.08,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(double screenWidth) {
    return FadeInUp(
      duration: Duration(milliseconds: 800),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          "Your premier solution for seamlessly managing expenses and equitably dividing bills among friends. Designed with precision by our adept developers, Aryan Bansal and Depankar Singh, Settleup ensures a sophisticated yet effortless experience in financial coordination.",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.04,
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          duration: Duration(milliseconds: 1000),
          child: Text(
            "Meet Our Team",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        _buildDeveloperCard(
          name: "Depankar Singh",
          linkedin: "https://www.linkedin.com/in/deepankar0611",
          instagram: "https://www.instagram.com/ideepankarsingh_?igsh=MTdiMDdqYjE3YXl5ag==",
          screenWidth: screenWidth,
          delay: 1400,
        ),
        SizedBox(height: screenHeight * 0.02),
        _buildDeveloperCard(
          name: "Aryan Bansal",
          linkedin: "https://www.linkedin.com/in/aryan-bansal-958686241",
          instagram: "https://www.instagram.com/_aryan_agrawal?igsh=YTNmd2Mxdzh6NHo2",
          screenWidth: screenWidth,
          delay: 1200,
        ),
      ],
    );
  }

  Widget _buildDeveloperCard({
    required String name,
    required String linkedin,
    required String instagram,
    required double screenWidth,
    required int delay,
  }) {
    return FadeInUp(
      duration: Duration(milliseconds: delay),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            _buildSocialLink(
              icon: 'assets/icons/linkedin.svg', // Add LinkedIn SVG icon in assets
              label: "LinkedIn",
              url: linkedin,
              color: Colors.blue.shade300,
              screenWidth: screenWidth,
            ),
            SizedBox(height: screenWidth * 0.02),
            _buildSocialLink(
              icon: 'assets/icons/instagram.svg', // Add Instagram SVG icon in assets
              label: "Instagram",
              url: instagram,
              color: Colors.pink.shade300,
              screenWidth: screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLink({
    required String icon,
    required String label,
    required String url,
    required Color color,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: screenWidth * 0.06,
            height: screenWidth * 0.06,
            color: color,
          ),
          SizedBox(width: screenWidth * 0.03),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(double screenWidth) {
    return FadeInUp(
      duration: Duration(milliseconds: 1600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Get in Touch",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "For assistance or inquiries, contact us at:",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: screenWidth * 0.01),
                GestureDetector(
                  onTap: () => _launchUrl("mailto:ad.dev8b@gmail.com"),
                  child: Text(
                    "ad.dev8b@gmail.com",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      color: Colors.blue.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animation widget for fade-in effects
class FadeInDown extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeInDown({required this.child, required this.duration});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -50, end: 0),
      duration: duration,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: (50 + value) / 50,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeInUp({required this.child, required this.duration});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 50, end: 0),
      duration: duration,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: (50 - value) / 50,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class FadeInLeft extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeInLeft({required this.child, required this.duration});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -50, end: 0),
      duration: duration,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(value, 0),
          child: Opacity(
            opacity: (50 + value) / 50,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}