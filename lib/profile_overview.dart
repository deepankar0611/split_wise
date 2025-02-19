import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'editprofile.dart';

class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId'; // Fetching user ID from FirebaseAuth
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  // User Data
  Map<String, dynamic> userData = {
    "name": "User",
    "email": "",
    "profileImageUrl": "",
    "totalBalance": 0.0,
    "amountOwed": 0.0,
    "amountLent": 0.0,
  };

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Fetch User Data from Firestore
  Future<void> _fetchUserData() async {
    if (userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {}; // Ensure we get a non-null map
        if (mounted) {
          // Check if the widget is still mounted
          setState(() {
            userData = {
              "name": data["name"] ?? "User",
              "email": data["email"] ?? "",
              "profileImageUrl": data.containsKey("profileImageUrl")
                  ? data["profileImageUrl"]
                  : "",
              "totalBalance": data["totalBalance"] ?? 0.0,
              "amountOwed": data["amountOwed"] ?? 0.0,
              "amountLent": data["amountLent"] ?? 0.0,
            };
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }



  /// Upload Image to Supabase and Update Firestore
  Future<void> _uploadProfileImage() async {
    try {
      // Request permission to access gallery (runtime permission check)

      // Pick the image from gallery
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return; // If no image is picked

      setState(() => _isUploading = true);

      final File file = File(pickedFile.path);
      final String fileName = 'profile_pictures/$userId-${basename(file.path)}';

      // Convert File to Uint8List
      final Uint8List imageBytes = await file.readAsBytes();

      // Upload to Supabase Storage (background thread)
      await Future.delayed(Duration.zero, () async {
        await supabase.storage.from('profile_pictures').uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(upsert: true),
        );

        // Get Public Image URL
        final imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);

        // Update Firestore with new image URL
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profileImageUrl': imageUrl,
        });

        setState(() {
          userData['profileImageUrl'] = imageUrl;
          _isUploading = false;
        });


      });
    } catch (e) {
      print("Error uploading image: $e");
      setState(() => _isUploading = false);

    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Profile Overview",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF234567),
        elevation: 4, // Adds shadow for depth
        centerTitle: true, // Centers the title
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ), // Rounded bottom corners
        toolbarHeight: 50,

        actions: [
          IconButton( // Edit Button in AppBar
            icon: const Icon(Icons.edit, color: Colors.white), // Ensure icon color is white for visibility
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));// Navigate to Edit Profile Screen
            },
            tooltip: 'Edit Profile', // Accessibility tooltip
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildFinanceSummary(),
            const SizedBox(height: 20),
            _buildProfileOptions(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Profile Header with Image and User Info
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: userData["profileImageUrl"].isNotEmpty
                    ? NetworkImage(userData["profileImageUrl"])
                    : const AssetImage('assets/logo/intro.jpeg')
                as ImageProvider,
              ),
              if (_isUploading) const CircularProgressIndicator(),
              GestureDetector(
                onTap: _uploadProfileImage,
                child: _editIcon(),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userData["name"],
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(userData["email"],
                    style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Finance Summary
  Widget _buildFinanceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryTile("Total Balance", "₹${userData["totalBalance"]}"),
          _buildSummaryTile(
              "Amount Owed", "₹${userData["amountOwed"]}", Colors.red),
          _buildSummaryTile(
              "Amount Lent", "₹${userData["amountLent"]}", Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // Profile Options
  Widget _buildProfileOptions(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(Icons.people, "Manage Friends", '/friendsList', context),
        _buildOptionTile(Icons.history, "Expense History", '/expenseHistory', context),
        _buildOptionTile(Icons.settings, "Settings", '/settings', context),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _logout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Red color for logout button
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          ),
          child: const Text(
            "Logout",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// **Logout Function**
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, 'LoginScreen()'); // Redirect to login page
    } catch (e) {
      print("Logout failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
    }
  }

  Widget _buildOptionTile(IconData icon, String title, String route, context) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
    ],
  );

  Widget _editIcon() => const Icon(Icons.camera_alt, color: Colors.black);
}