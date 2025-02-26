import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;
  File? _image;
  String? _selectedAvatar;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';

  // List of avatar options using the Supabase URL
  final List<String> avatarOptions = [
    'https://xzoyevujxvqaumrdskhd.supabase.co/storage/v1/object/public/profile_pictures/profile_pictures/new%201.png',
    'https://xzoyevujxvqaumrdskhd.supabase.co/storage/v1/object/public/profile_pictures/profile_pictures/androgynous-avatar-non-binary-queer-person.png',
    'https://xzoyevujxvqaumrdskhd.supabase.co/storage/v1/object/public/profile_pictures/profile_pictures/3d-rendered-illustration-cartoon-character-with-face-picture-frame.jpg',
  ];

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
          _nameController.text = data["name"] ?? "User";
          _phoneController.text = data["phone"] ?? "";
          _selectedAvatar = data["profileImageUrl"]; // Use profileImageUrl instead of avatarUrl
        });
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
        _selectedAvatar = null; // Clear avatar if custom image is selected
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final filePath = 'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('profile_pictures').upload(filePath, _image!);
      final imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(filePath);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': imageUrl,
      });
    } catch (e) {
      print('Image upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  Future<void> _selectAvatar(String avatarUrl) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;
      setState(() {
        _selectedAvatar = avatarUrl; // Store the Supabase URL
        _image = null; // Clear custom image if avatar is selected
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': avatarUrl, // Store the Supabase URL in profileImageUrl
      });
    } catch (e) {
      print('Avatar selection failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select avatar: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("User not logged in");
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 200,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: avatarOptions.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _selectAvatar(avatarOptions[index]);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(avatarOptions[index]), // Load from Supabase URL
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading avatar: $exception');
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.06),
        child: AppBar(
          backgroundColor: Color(0xFF234567),
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: screenWidth * 0.045,
            ),
          ),
          centerTitle: true,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.back, color: Colors.white, size: screenWidth * 0.06),
            onPressed: () => Navigator.pop(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white],
                ),
              ),
              child: CustomPaint(painter: FloatingBackgroundPainter()),
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
              final profileImageUrl = userData?['profileImageUrl'] as String? ?? '';

              return Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: screenWidth * 0.005),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: screenWidth * 0.02,
                                  offset: Offset(0, screenWidth * 0.01),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: screenWidth * 0.18,
                              backgroundColor: Colors.white,
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : _selectedAvatar != null && _selectedAvatar!.isNotEmpty
                                  ? NetworkImage(_selectedAvatar!) // Supabase URL
                                  : profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl) // Supabase URL
                                  : AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                              onBackgroundImageError: (exception, stackTrace) {
                                print('Error loading profile image: $exception');
                              },
                            ),
                          ),
                          Positioned(
                            bottom: screenWidth * 0.025,
                            right: -screenWidth * 0.05,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: screenWidth * 0.002),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: screenWidth * 0.01,
                                      offset: Offset(0, screenWidth * 0.005),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                child: Icon(CupertinoIcons.photo, color: Colors.green, size: screenWidth * 0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: screenWidth * 0.025,
                            right: screenWidth * 0.05,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _showAvatarPicker,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: screenWidth * 0.002),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: screenWidth * 0.01,
                                      offset: Offset(0, screenWidth * 0.005),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                child: Icon(CupertinoIcons.person_circle, color: Colors.blue, size: screenWidth * 0.06),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    buildTextField(
                      "Name",
                      "Enter your name",
                      _nameController,
                      CupertinoIcons.person_fill,
                      fontSize: screenWidth * 0.04,
                    ),
                    buildTextField(
                      "Phone",
                      "Enter your phone",
                      _phoneController,
                      CupertinoIcons.phone_fill,
                      keyboardType: TextInputType.phone,
                      fontSize: screenWidth * 0.04,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    CupertinoButton(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015, horizontal: screenWidth * 0.02),
                      color: const Color(0xFF234567),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      onPressed: _saveProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26.withOpacity(0.3),
                              spreadRadius: 0.5,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.zero,
                        child: RichText(
                          text: TextSpan(
                            text: 'Save ',
                            style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold, color: Colors.white),
                            children: [
                              TextSpan(
                                text: 'Update',
                                style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
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

  Widget buildTextField(
      String labelText,
      String hintText,
      TextEditingController controller,
      IconData prefixIcon, {
        bool obscureText = false,
        TextInputType? keyboardType,
        IconData? suffixIcon,
        required double fontSize,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: screenWidth * 0.012),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: fontSize * 0.9,
                ),
                children: [TextSpan(text: labelText)],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: screenWidth * 0.002,
                  blurRadius: screenWidth * 0.012,
                  offset: Offset(0, screenWidth * 0.007),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: fontSize, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(fontSize: fontSize * 0.9, color: Colors.grey.shade500),
                prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: fontSize * 1.2),
                suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey.shade600, size: fontSize * 1.2) : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.045),
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
    for (int i = 0; i < 5; i++) {
      final startPoint = Offset(0, size.height * random.nextDouble());
      final endPoint = Offset(size.width, size.height * random.nextDouble());
      final paint = Paint()
        ..color = Colors.green.shade200.withOpacity(0.3)
        ..strokeWidth = size.width * 0.004;
      canvas.drawLine(startPoint, endPoint, paint);
    }
    for (int i = 0; i < 20; i++) {
      final center = Offset(size.width * random.nextDouble(), size.height * random.nextDouble());
      final radius = random.nextDouble() * (size.width * 0.04) + (size.width * 0.012);
      final paint = Paint()
        ..color = Color.fromRGBO(random.nextInt(256), random.nextInt(256), random.nextInt(256), 0.1);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}