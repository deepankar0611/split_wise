import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileOverviewScreen extends StatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  State<ProfileOverviewScreen> createState() => _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends State<ProfileOverviewScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  // User Data
  Map<String, dynamic> userData = {
    "name": "User",
    "email": "",
    "profileImageUrl": "",
    "dob": "",
    "gender": "",
    "bloodType": "",
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() {
          userData = {
            "name": doc['name'] ?? "User",
            "email": doc['email'] ?? "",
            "profileImageUrl": doc['profileImageUrl'] ?? "",
            "dob": doc['dob'] ?? "",
            "gender": doc['gender'] ?? "",
            "bloodType": doc['bloodType'] ?? "",
            "totalBalance": doc['totalBalance'] ?? 0.0,
            "amountOwed": doc['amountOwed'] ?? 0.0,
            "amountLent": doc['amountLent'] ?? 0.0,
          };
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      _showSnackBar("Failed to fetch user data.", context);
    }
  }

  /// Upload Image to Supabase and Update Firestore
  Future<void> _uploadProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final File imageFile = File(pickedFile.path);
      final String fileName = 'profile_pictures/$userId-${basename(imageFile.path)}';

      // Convert File to Uint8List
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
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

      _showSnackBar("Profile image updated successfully!", context);
    } catch (e) {
      print("Error uploading image: $e");
      setState(() => _isUploading = false);
      _showSnackBar("Image upload failed.", context);
    }
  }

  /// Logout User
  Future<void> _logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Helper to Show SnackBar
  void _showSnackBar(String message, context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile Overview"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/editProfile');
            },
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
            _buildProfileOptions(),
            const SizedBox(height: 20),
            _buildLogoutButton(),
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
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
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
                Text(userData["name"], style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(userData["email"], style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                Text("DOB: ${userData["dob"]}", style: GoogleFonts.poppins(fontSize: 14)),
                Text("Gender: ${userData["gender"]}", style: GoogleFonts.poppins(fontSize: 14)),
                Text("Blood Type: ${userData["bloodType"]}", style: GoogleFonts.poppins(fontSize: 14)),
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
          _buildSummaryTile("Amount Owed", "₹${userData["amountOwed"]}", Colors.red),
          _buildSummaryTile("Amount Lent", "₹${userData["amountLent"]}", Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // Profile Options
  Widget _buildProfileOptions() {
    return Column(
      children: [
        _buildOptionTile(Icons.people, "Manage Friends", '/friendsList', context),
        _buildOptionTile(Icons.history, "Expense History", '/expenseHistory', context),
        _buildOptionTile(Icons.settings, "Settings", '/settings', context),
      ],
    );
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

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () => _logout(context),
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text("Logout"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
  );

  Widget _editIcon() => const Icon(Icons.camera_alt, color: Colors.white);
}
