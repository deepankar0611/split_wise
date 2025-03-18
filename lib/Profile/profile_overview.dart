import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:split_wise/Profile/manage_friends.dart';
import 'package:split_wise/Profile/setting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login signup/login_screen.dart';
import 'about_us_screen.dart';
import 'all expense history detals.dart';
import 'editprofile.dart';

class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  final SupabaseClient supabase = Supabase.instance.client;

  Map<String, dynamic> userData = {
    "name": "User",
    "email": "",
    "profileImageUrl": "",
    "phone_number": "",
    "amountToPay": "0",
    "amountToReceive": "0",
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (userId == 'defaultUserId') return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          userData = {
            "name": data["name"] as String? ?? "User",
            "email": data["email"] as String? ?? "",
            "profileImageUrl": data["profileImageUrl"] as String? ?? "",
            "phone_number": data["phone"] as String? ?? "",
            "amountToPay": data["amountToPay"]?.toString() ?? "0",
            "amountToReceive": data["amountToReceive"]?.toString() ?? "0",
          };
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.06),
        child: AppBar(
          title: Text(
            "Profile Overview",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A3C6D), // Base: Deep neon blue
                  Color(0xFF0A2A4D), // Darker neon blue (shadowy tone)
                  Color(0xFF1A3C6D),// Neon purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1A3C6D).withOpacity(0.5),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
          ),
          elevation: 4,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white, size: screenWidth * 0.06),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
              },
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              _buildProfileHeader(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.03),
              _buildFinanceSummary(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.03),
              _buildProfileOptions(context, screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.1), // Extra padding to avoid overlap with FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _buildLogoutButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Profile Header (unchanged for brevity)
  Widget _buildProfileHeader(double screenWidth, double screenHeight) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.teal));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No user data found', style: GoogleFonts.poppins()));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final profileImageUrl = userData['profileImageUrl'] as String? ?? '';

        return Card(
          elevation: screenWidth * 0.02,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
          shadowColor: Colors.black.withOpacity(0.2),
          child: Stack(
            children: [
              Container(
                height: screenHeight * 0.18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0288D1), Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
              ),
              Positioned(
                left: screenWidth * 0.04,
                bottom: screenHeight * 0.02,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showFullImage(context, profileImageUrl, screenWidth);
                      },
                      child: CircleAvatar(
                        radius: screenWidth * 0.1,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'] as String? ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
                          ),
                        ),
                        Text(
                          userData['email'] as String? ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          userData['phone'] as String? ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageUrl, double screenWidth) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(screenWidth * 0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: screenWidth * 0.6,
              height: screenWidth * 0.6,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
              ),
            ),
          ),
        );
      },
    );
  }

  // Finance Summary (unchanged for brevity)
  Widget _buildFinanceSummary(double screenWidth, double screenHeight) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.teal));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No financial data available', style: GoogleFonts.poppins()));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        double amountToPay = double.tryParse(userData["amountToPay"]?.toString() ?? "0") ?? 0;
        double amountToReceive = double.tryParse(userData["amountToReceive"]?.toString() ?? "0") ?? 0;
        double totalBalance = amountToReceive - amountToPay;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: snapshot.hasData && snapshot.data!.exists ? 1.0 : 0.0,
          child: Card(
            elevation: screenWidth * 0.02,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
            shadowColor: Colors.teal.withOpacity(0.4),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF234567), Color(0xFF234567)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
              ),
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryTile("Total Balance", "₹${totalBalance.toStringAsFixed(2)}", Colors.white, screenWidth),
                  VerticalDivider(color: Colors.white, thickness: 1, width: screenWidth * 0.04),
                  _buildSummaryTile("Pay", "₹${amountToPay.toStringAsFixed(2)}", Colors.white, screenWidth),
                  VerticalDivider(color: Colors.white, thickness: 1, width: screenWidth * 0.04),
                  _buildSummaryTile("Receive", "₹${amountToReceive.toStringAsFixed(2)}", Colors.white, screenWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile(String label, String value, Color? color, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: screenWidth * 0.03, color: Colors.white),
        ),
      ],
    );
  }

  // Updated Profile Options
  Widget _buildProfileOptions(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5, // Minimum height to ensure visibility
      ),
      child: ListView.builder(
        shrinkWrap: true, // Makes the ListView take only the space it needs
        physics: const NeverScrollableScrollPhysics(), // Disable inner scroll, let parent handle it
        itemCount: 5,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _buildOptionTile(
                icon: Icons.people,
                title: "Manage Friends",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsList())),
                iconColor: const Color(0xFF0288D1),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 1:
              return _buildOptionTile(
                icon: Icons.history,
                title: "Expense History",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpenseHistoryDetailedScreen(sendFilter: '', splitId: '', showFilter: '')),
                ),
                iconColor: const Color(0xFF7B1FA2),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 2:
              return _buildOptionTile(
                icon: Icons.settings,
                title: "Settings",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                iconColor: const Color(0xFF00897B),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 3:
              return _buildOptionTile(
                icon: CupertinoIcons.info,
                title: "About Us",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen())),
                iconColor: const Color(0xFF6A1B9A),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 4:
              return _buildOptionTile(
                icon: Icons.star,
                title: "Rate Us",
                onTap: () => _showRateUsDialog(context),
                iconColor: const Color(0xFFF57C00),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            default:
              return Container();
          }
        },
      ),
    );
  }

  void _showAboutUsDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue.shade50,
        title: Text("About Us", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.06)),
        content: Text(
          "Welcome to Settleup, your premier solution for seamlessly managing expenses and equitably dividing bills among friends. Designed with precision by our adept developers, Aryan Bansal and Depankar Singh, SplitWise ensures a sophisticated yet effortless experience in financial coordination. For further details or assistance, please feel free to reach out to us at ad.dev8b@gmail.com. Should you encounter any issues or wish to lodge a complaint, we encourage you to raise your concerns via the same email address, where our dedicated team stands ready to assist you.",
          style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: Colors.blue.shade500, fontSize: screenWidth * 0.04)),
          ),
        ],
      ),
    );
  }

  void _showRateUsDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rate Us", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05)),
        content: Text(
          "If you enjoy using SplitWise, please rate us on the App Store or Google Play to help us improve!",
          style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later", style: GoogleFonts.poppins(color: Colors.teal, fontSize: screenWidth * 0.04)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add logic to open app store/play store (e.g., with url_launcher)
            },
            child: Text("Rate Now", style: GoogleFonts.poppins(color: Colors.teal, fontSize: screenWidth * 0.04)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.95),
          onTapUp: (_) {
            setState(() => scale = 1.0);
            _logout(context);
          },
          onTapCancel: () => setState(() => scale = 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(scale),
            child: FloatingActionButton(
              onPressed: null,
              backgroundColor: const Color(0xFF234567),
              elevation: screenWidth * 0.015,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.075)),
              child: Icon(LucideIcons.logOut, size: screenWidth * 0.06, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      print("Logout failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error logging out: $e")));
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color backgroundColor,
    required double screenWidth,
    required double screenHeight,
    Function()? onTap,
  }) {
    return Card(
      elevation: screenWidth * 0.01,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
      shadowColor: Colors.teal.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.005),
          leading: Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Icon(icon, color: iconColor, size: screenWidth * 0.06),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal.shade700, size: screenWidth * 0.05),
          onTap: onTap,
        ),
      ),
    );
  }
}