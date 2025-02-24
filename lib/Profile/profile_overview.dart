import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:split_wise/Profile/manage_friends.dart';
import 'package:split_wise/Profile/setting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Search/search_bar.dart';
import '../login signup/login_screen.dart';
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
    "amountToPay": "",
    "amountToReceive": "",
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
      if (doc.exists) {
        final data = doc.data() ?? {};
        if (mounted) {
          setState(() {
            userData = {
              "name": data["name"] ?? "User",
              "email": data["email"] ?? "",
              "profileImageUrl": data.containsKey("profileImageUrl") ? data["profileImageUrl"] : "",
              "amountToPay": data["amountToPay"],
              "amountToReceive": data["amountToReceive"],
            };
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Profile Overview",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF234567),
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        toolbarHeight: 50,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(screenWidth, screenHeight),
            const SizedBox(height: 20),
            _buildFinanceSummary(screenWidth, screenHeight),
            const SizedBox(height: 20),
            _buildProfileOptions(context),
            const SizedBox(height: 20), // Removed _buildLogoutButton here
          ],
        ),
      ),
      floatingActionButton: _buildLogoutButton(context), // Added FAB at the bottom
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Position at bottom right
    );
  }

  Widget _buildProfileHeader(double screenWidth, double screenHeight) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('No user data found', style: GoogleFonts.poppins()));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shadowColor: Colors.black.withOpacity(0.2),
          child: Stack(
            children: [
              Container(
                height: screenHeight * 0.18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: userData.containsKey('profileImageUrl') && userData['profileImageUrl'].isNotEmpty
                          ? NetworkImage(userData['profileImageUrl'] as String)
                          : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'] ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
                          ),
                        ),
                        Text(
                          userData['email'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                        ),
                        Text(
                          userData['phone'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
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

  Widget _buildFinanceSummary(double screenWidth, double screenHeight) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
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
        Color balanceColor = totalBalance >= 0 ? Colors.green.shade600 : Colors.red.shade600;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500), // Fade-in animation
          opacity: snapshot.hasData && snapshot.data!.exists ? 1.0 : 0.0,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            shadowColor: Colors.teal.withOpacity(0.4),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF234567), Color(0xFF234567)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryTile("Total Balance", "₹${totalBalance.toStringAsFixed(2)}", Colors.white),
                  const VerticalDivider(
                    color: Colors.white,
                    thickness: 1,
                    width: 16, // Space between tiles
                  ),
                  _buildSummaryTile("Pay", "₹${amountToPay.toStringAsFixed(2)}", Colors.white),
                  const VerticalDivider(
                    color: Colors.white,
                    thickness: 1,
                    width: 16,
                  ),
                  _buildSummaryTile("Receive", "₹${amountToReceive.toStringAsFixed(2)}", Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated _buildSummaryTile to use smaller text
  Widget _buildSummaryTile(String label, String value, [Color? color]) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Compact vertical size
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16, // Smaller text for values
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white), // Smaller text for labels
        ),
      ],
    );
  }

  Widget _buildProfileOptions(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: 300, // Increased height to accommodate 5 items (from 240)
      child: ListView.builder(
        itemCount: 5, // Updated to include 5 items
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _buildOptionTile(
                icon: Icons.people,
                title: "Manage Friends",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FriendsList()),
                  );
                },
                iconColor: const Color(0xFF0288D1),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 1:
              return _buildOptionTile(
                icon: Icons.history,
                title: "Expense History",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpenseHistoryDetailedScreen(showFilter: '', splitId: '')),
                  );
                },
                iconColor: const Color(0xFF7B1FA2),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 2:
              return _buildOptionTile(
                icon: Icons.settings,
                title: "Settings",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                iconColor: const Color(0xFF00897B),
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 3:
              return _buildOptionTile(
                icon: Icons.info, // Icon for About Us
                title: "About Us",
                onTap: () {
                  // Add navigation or action for About Us (e.g., show a dialog, navigate to a new screen)
                  _showAboutUsDialog(context); // Example implementation below
                },
                iconColor: const Color(0xFF6A1B9A), // Purple for variety
                backgroundColor: Colors.white,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            case 4:
              return _buildOptionTile(
                icon: Icons.star, // Icon for Rate Us
                title: "Rate Us",
                onTap: () {
                  // Add action for Rate Us (e.g., open app store or show a rating dialog)
                  _showRateUsDialog(context); // Example implementation below
                },
                iconColor: const Color(0xFFF57C00), // Orange for variety
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

  // Helper method to show About Us dialog
  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("About Us", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Welcome to SplitWise! We help you manage your expenses and split bills with friends effortlessly. Contact us at support@splitwise.com for more information.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  // Helper method to show Rate Us dialog
  void _showRateUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rate Us", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "If you enjoy using SplitWise, please rate us on the App Store or Google Play to help us improve!",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later", style: GoogleFonts.poppins(color: Colors.teal)),
          ),
          TextButton(
            onPressed: () {
              // Add logic to open the app store or play store here (e.g., using url_launcher package)
              Navigator.pop(context);
            },
            child: Text("Rate Now", style: GoogleFonts.poppins(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
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
              onPressed: null, // Disable default onPressed to use GestureDetector
              backgroundColor: const Color(0xFF234567),
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: const Icon(LucideIcons.logOut, size: 24, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Logout failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.teal.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenHeight * 0.005,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.teal.shade700,
            size: screenWidth * 0.05,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}