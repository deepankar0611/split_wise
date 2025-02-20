import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:uuid/uuid.dart';


class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _email = TextEditingController();
  final supabase = Supabase.instance.client;
  File? _image;
  String? _imageUrl;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId'; // Fetching user ID from FirebaseAuth

  Map<String, dynamic> userData = {
    "name": "User",
    "email": "",
    "profileImageUrl": "",
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() ?? {}; // Ensure we get a non-null map
        if (mounted) {
          setState(() {
            _nameController.text = data["name"] ?? "User";
            _phoneController.text = data["phone"] ?? "";
            _email = data["email"] ?? ""; // Since email is not editable, store it in a variable
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }



  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;

      if (user == null) return;
      final String filePath = 'profile_pictures/${user.uid}${DateTime.now()}.jpg';
      await supabase.storage.from('profile_pictures').upload(filePath, _image!);
      final String imageUrl =
      supabase.storage.from('profile_pictures').getPublicUrl(filePath);



      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': imageUrl,
      });
    } catch (e) {
      print('Image upload failed: $e');
    }
  }

  Future<void> _saveProfile() async {
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Firestore update (only name and phone)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );

        Navigator.pop(context); // Go back after saving
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile. Try again.')),
        );
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF234567),
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ), // Rounded bottom corners
        toolbarHeight: 50, // Increased height for prominence
      ),
      body: Stack(
        // Use Stack for background elements
        children: [
          Positioned.fill( // Background Lines and Circles
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF0F9F4),
                    Color(0xFFE0F2E9),
                    Color(0xFFC8E6C9),
                    Colors.white,
                  ],
                  stops: [0.1, 0.3, 0.6, 0.9],
                ),
              ),
              child: CustomPaint( // CustomPaint for lines and circles
                painter: FloatingBackgroundPainter(),
              ),
            ),
          ),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: getUserStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("User data not found"));
              }

              final userData = snapshot.data!.data();
              final profileImageUrl = userData?['profileImageUrl'] ?? '';

              return Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: <Widget>[
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white,
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 0,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                padding: EdgeInsets.all(8),
                                child: Icon(CupertinoIcons.add, color: Colors.green, size: 25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    buildTextField("Name", "Enter your name", _nameController, CupertinoIcons.person_fill),
                    buildTextField("Phone", "Enter your phone", _phoneController, CupertinoIcons.phone_fill, keyboardType: TextInputType.phone),
                    SizedBox(height: 30),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      color: const Color(0xFF234567), // Custom color
                      onPressed: _saveProfile,
                      child: RichText(
                        text: const TextSpan(
                          text: 'Save ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Update',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Custom color for part of the text
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget buildTextField(String labelText, String hintText, TextEditingController controller, IconData prefixIcon, {bool obscureText = false, TextInputType? keyboardType, IconData? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
                children: <TextSpan>[
                  TextSpan(text: labelText, style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
                suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey.shade600) : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();

    // Draw Lines
    for (int i = 0; i < 5; i++) { // Draw 5 lines
      final startPoint = Offset(0, size.height * random.nextDouble());
      final endPoint = Offset(size.width, size.height * random.nextDouble());
      final paint = Paint()
        ..color = Colors.green.shade200.withOpacity(0.3) // Light green lines
        ..strokeWidth = 1.5;
      canvas.drawLine(startPoint, endPoint, paint);
    }

    // Draw Circles
    for (int i = 0; i < 20; i++) { // Draw 20 circles
      final center = Offset(size.width * random.nextDouble(), size.height * random.nextDouble());
      final radius = random.nextDouble() * 15 + 5; // Radius between 5 and 20
      final paint = Paint()
        ..color = Color.fromRGBO(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
          0.1, // Low opacity for circles
        );
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}