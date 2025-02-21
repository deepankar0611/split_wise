import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:split_wise/Profile/manage_friends.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Search/search_bar.dart';
import '../login signup/login_screen.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
            Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: _buildProfileHeader(),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: _buildFinanceSummary(),
            ),
            const SizedBox(height: 20),
            _buildProfileOptions(context),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
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
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
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
        );
      },
    );
  }

  Widget _buildFinanceSummary() {
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

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryTile("Total Balance", "₹${totalBalance.abs().toInt()}", balanceColor),
              _buildSummaryTile("Pay", "₹${amountToPay.toInt()}", Colors.red.shade600),
              _buildSummaryTile("Receive", "₹${amountToReceive.toInt()}", Colors.green.shade600),
            ],
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
    return Column(
      children: [
        Card(
          elevation: 8,
          shadowColor: Colors.teal.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: _buildOptionTile(
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
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 8,
          shadowColor: Colors.teal.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: _buildOptionTile(
            icon: Icons.history,
            title: "Expense History",
            route: '/expenseHistory',
            context: context,
            iconColor: const Color(0xFF7B1FA2),
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 8,
          shadowColor: Colors.teal.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: _buildOptionTile(
            icon: Icons.settings,
            title: "Settings",
            route: '/settings',
            context: context,
            iconColor: const Color(0xFF00897B),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.teal.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        height: 60,
        width: 160,
        child: ElevatedButton(
          onPressed: () => _logout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF234567),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, size: 19, color: Colors.white),
              SizedBox(width: 8),
              Text("Logout"),
            ],
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
    String? route,
    required Color iconColor,
    required Color backgroundColor,
    Function()? onTap,
    BuildContext? context,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
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
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 18),
        onTap: onTap ??
            (context != null && route != null
                ? () => Navigator.pushNamed(context, route)
                : null),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}