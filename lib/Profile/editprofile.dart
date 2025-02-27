import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserData());
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
        final data = doc.data() ?? {};
        _nameController.text = data["name"] ?? "User";
        _phoneController.text = data["phone"] ?? "";
        _imageUrl = data["profileImageUrl"];
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
        _imageUrl = null; // Clear previous URL when new image is picked
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
      if (mounted) setState(() => _imageUrl = imageUrl);
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
        _image = null; // Clear custom image if avatar is selected
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'profileImageUrl': avatarUrl},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Avatar selection failed: $e');
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
          const SnackBar(content: Text('Profile updated successfully!')),
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.error(Exception("User not logged in"));
    }
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
  }

  void _showAvatarPicker() {
    if (_isLoading || !mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: GridView.builder(
          physics: const ClampingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
              backgroundImage: NetworkImage(avatarOptions[index]),
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading avatar: $exception');
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF234567),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
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
        toolbarHeight: 50,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.white, Colors.white],
                  stops: [0.1, 0.3, 0.6, 0.9],
                ),
              ),
              child: CustomPaint(painter: FloatingBackgroundPainter()),
            ),
          ),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: getUserStream(),
            builder: (context, snapshot) {
              if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("User data not found"));
              }

              final userData = snapshot.data!.data();
              final profileImageUrl = userData?['profileImageUrl'] as String? ?? '';

              return Form(
                key: _formKey,
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 70,
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
                            bottom: 10,
                            right: -10,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _isLoading ? null : _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(CupertinoIcons.add, color: Colors.green, size: 25),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 40,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _isLoading ? null : _showAvatarPicker,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(CupertinoIcons.person_circle, color: Colors.blue, size: 25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    buildTextField("Name", "Enter your name", _nameController, CupertinoIcons.person_fill),
                    PhoneNumberTextFieldWidget(controller: _phoneController, isLoading: _isLoading), // Use the new widget here
                    const SizedBox(height: 30),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      color: const Color(0xFF234567),
                      onPressed: _isLoading
                          ? null
                          : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : RichText(
                        text: const TextSpan(
                          text: 'Save ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Update',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                  TextSpan(text: labelText, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
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
              enabled: !_isLoading,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle:  TextStyle(fontSize: 14, color: Colors.grey.shade500),
                prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
                suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey.shade600) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                children: const <TextSpan>[
                  TextSpan(text: "Phone", style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _phoneFocusNode,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              inputFormatters: [PhoneInputFormatter()],
              decoration: InputDecoration(
                hintText: "Enter your phone (e.g., +1234567890)",
                hintStyle:  TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

    String formattedText = text.startsWith('+') ? text : '+$text';
    if (formattedText.length > 12) {
      formattedText = formattedText.substring(0, 12);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class FloatingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paintLine = Paint()
      ..color = Colors.green.shade200.withOpacity(0.3)
      ..strokeWidth = 1.5;
    final paintCircle = Paint();

    for (int i = 0; i < 5; i++) {
      final startPoint = Offset(0, size.height * random.nextDouble());
      final endPoint = Offset(size.width, size.height * random.nextDouble());
      canvas.drawLine(startPoint, endPoint, paintLine);
    }

    for (int i = 0; i < 20; i++) {
      final center = Offset(size.width * random.nextDouble(), size.height * random.nextDouble());
      final radius = random.nextDouble() * 15 + 5;
      paintCircle.color = Color.fromRGBO(random.nextInt(256), random.nextInt(256), random.nextInt(256), 0.1);
      canvas.drawCircle(center, radius, paintCircle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}