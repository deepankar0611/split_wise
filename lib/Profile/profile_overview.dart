import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:split_wise/Profile/manage_friends.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Search/search_bar.dart';
import '../login signup/login_screen.dart';
import 'all expense history detals.dart';
import 'editprofile.dart'; // Ensure this import is present
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
            const SizedBox(height: 20),
            _buildLogoutButton(screenWidth, screenHeight),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          shadowColor: Colors.teal.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.teal.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userData.containsKey('profileImageUrl') && userData['profileImageUrl'].isNotEmpty
                        ? NetworkImage(userData['profileImageUrl'] as String)
                        : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                    backgroundColor: Colors.teal.shade100,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'] ?? 'User',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          userData['email'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
                        ),
                        Text(
                          userData['phone'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          shadowColor: Colors.teal.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.teal.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryTile("Total Balance", "₹${totalBalance.abs().toInt()}", balanceColor),
                _buildSummaryTile("Pay", "₹${amountToPay.toInt()}", Colors.red.shade600),
                _buildSummaryTile("Receive", "₹${amountToReceive.toInt()}", Colors.green.shade600),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProfileOptions(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: 300, // Adjust height as needed to accommodate all cards
      child: ListView.builder(
        itemCount: 3, // Three options: Manage Friends, Expense History, Settings
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
                    MaterialPageRoute(builder: (context) => const ExpenseHistoryDetailedScreen()),
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
                  Navigator.pushNamed(context, '/settings');
                },
                iconColor: const Color(0xFF00897B),
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

  Widget _buildLogoutButton(double screenWidth, double screenHeight) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.teal.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // Match padding with other cards
          child: GestureDetector(
            onTap: () => _logout(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Ensures the row sizes to its content
              children: const [
                Icon(LucideIcons.logOut, size: 19, color: Colors.black),
                SizedBox(width: 8),
                Text("Logout", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
      ),
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.teal.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.01,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.teal.shade700,
            size: screenWidth * 0.07,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}