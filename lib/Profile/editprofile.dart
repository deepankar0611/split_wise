import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late final SupabaseClient supabase;
  File? _image;
  String? _imageUrl;
  late String userId;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  static const Color primaryColor = Color(0xFF234567);
  static const Color accentColor = Colors.tealAccent;

  static const List<String> avatarOptions = [
    'https://xzoyevujxvqaumrdskhd.supabase.co/storage/v1/object/public/profile_pictures/profile_pictures/new%201.png',
    'https://xzoyevujxvqaumrdskhd.supabase.co/storage/v1/object/public/profile_pictures/profile_pictures/androgynous-avatar-non-binary-queer-person.png',
    'https://xzoyevujxvqaumrdskhd.supabase.co/storage/v1/object/public/profile_pictures/profile_pictures/3d-rendered-illustration-cartoon-character-with-face-picture-frame.jpg',
  ];

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
    WidgetsBinding.instance.addObserver(this);
    _fetchUserData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _isLoading = false;
    }
  }

  Future<void> _fetchUserData() async {
    if (userId == 'defaultUserId' || !mounted) return;
    try {
      setState(() => _isLoading = true);
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!mounted) return;
      if (doc.exists) {
        _userData = doc.data() ?? {};
        _nameController.text = _userData!["name"] ?? "User";
        _phoneController.text = _userData!["phone"] ?? "";
        _imageUrl = _userData!["profileImageUrl"];
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user data')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (_isLoading || !mounted) return;
    try {
      setState(() => _isLoading = true);
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted || pickedFile == null) return;
      setState(() {
        _image = File(pickedFile.path);
        _imageUrl = null;
      });
      await _uploadImage();
    } catch (e) {
      print('Image picking failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null || !mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      final filePath = 'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('profile_pictures').upload(filePath, _image!);
      final imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(filePath);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'profileImageUrl': imageUrl},
        SetOptions(merge: true),
      );
      if (mounted) {
        setState(() {
        _imageUrl = imageUrl;
        _userData?['profileImageUrl'] = imageUrl;
      });
      }
    } catch (e) {
      print('Image upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  Future<void> _selectAvatar(String avatarUrl) async {
    if (_isLoading || !mounted) return;
    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      setState(() {
        _imageUrl = avatarUrl;
        _image = null;
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'profileImageUrl': avatarUrl},
        SetOptions(merge: true),
      );
      if (mounted) {
        setState(() {
        _imageUrl = avatarUrl;
        _userData?['profileImageUrl'] = avatarUrl;
      });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to select avatar')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading || !mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Profile updated successfully!', style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: primaryColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    if (_isLoading || !mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose an avatar", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.builder(
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: avatarOptions.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                    _selectAvatar(avatarOptions[index]);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(avatarOptions[index]),
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading avatar: $exception');
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    String profileImageUrl = _userData?['profileImageUrl'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 2,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        toolbarHeight: 45,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(25),
          children: <Widget>[
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    elevation: 8,
                    shadowColor: Colors.black45,
                    borderRadius: BorderRadius.circular(75),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.white,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : _imageUrl != null && _imageUrl!.isNotEmpty
                          ? NetworkImage(_imageUrl!)
                          : profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: -5,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isLoading ? null : _pickImage,
                      child: Material(
                        elevation: 6,
                        shadowColor: Colors.black26,
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Icon(CupertinoIcons.camera_fill, color: accentColor, size: 28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    left: -5,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isLoading ? null : _showAvatarPicker,
                      child: Material(
                        elevation: 6,
                        shadowColor: Colors.black26,
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Icon(CupertinoIcons.person_circle_fill, color: accentColor, size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            buildTextField("Name", "Enter your name", _nameController, CupertinoIcons.person_fill),
            PhoneNumberTextFieldWidget(controller: _phoneController, isLoading: _isLoading),
            const SizedBox(height: 40),
            ElevatedButton( // Replaced CupertinoButton with ElevatedButton
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Use primary color
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners
                elevation: 3, // Add elevation for shadow
              ),
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                'Save Profile',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              labelText,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 17,
              ),
            ),
          ),
          Material(
            elevation: 3,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(15),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              enabled: !_isLoading,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle:  GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade500),
                prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
                suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey.shade600) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:  BorderSide(color: accentColor, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New StatefulWidget for Phone Number Text Field
class PhoneNumberTextFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;

  const PhoneNumberTextFieldWidget({
    Key? key,
    required this.controller,
    required this.isLoading,
  }) : super(key: key);

  @override
  _PhoneNumberTextFieldWidgetState createState() => _PhoneNumberTextFieldWidgetState();
}

class _PhoneNumberTextFieldWidgetState extends State<PhoneNumberTextFieldWidget> {
  late final FocusNode _phoneFocusNode;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode = FocusNode();
    _phoneFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Phone",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 17,
              ),
            ),
          ),
          Material(
            elevation: 3,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(15),
            child: TextField(
              controller: widget.controller,
              focusNode: _phoneFocusNode,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              inputFormatters: [PhoneInputFormatter()],
              decoration: InputDecoration(
                hintText: "Enter your phone (e.g., +1234567890)",
                hintStyle:  GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade500),
                prefixIcon:  Icon(CupertinoIcons.phone_fill, color: Colors.grey.shade600),
                suffixIcon: widget.controller.text.isNotEmpty && _phoneFocusNode.hasFocus && !widget.isLoading
                    ? IconButton(
                  icon:  Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:  BorderSide(color: Colors.black, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
                ),
              ),
              onTapOutside: (_) {
                if (_phoneFocusNode.hasFocus && !widget.isLoading) {
                  _phoneFocusNode.unfocus();
                }
              },
              onSubmitted: (_) {
                if (!widget.isLoading) {
                  _phoneFocusNode.unfocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (text.isEmpty) return newValue;

    String formattedText = text.startsWith('+') ? text : '+91$text';
    if (formattedText.length > 13) {
      formattedText = formattedText.substring(0, 13);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
