import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  String? _profileImage;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
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
      ),
      body: Stack( // Use Stack for background elements
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
          Form( // Foreground Form content
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImage != null
                              ? AssetImage(_profileImage!) as ImageProvider<Object>?
                              : NetworkImage('https://via.placeholder.com/150') ,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 0,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            // TODO: Implement image selection logic
                            setState(() {
                              _profileImage = 'assets/temp_profile.png';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Image selection functionality to be implemented')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
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
                buildTextField("Name", "Annette Black", _nameController, CupertinoIcons.person_fill),
                buildTextField("Email", "annette@gmail.com", _emailController, CupertinoIcons.mail_solid, keyboardType: TextInputType.emailAddress),
                buildTextField("Phone", "(316) 555-0116", _phoneController, CupertinoIcons.phone_fill, keyboardType: TextInputType.phone),
                buildTextField("Address", "New York, NVC", _addressController, CupertinoIcons.location_solid),
                buildTextField("Old Password", "******", _oldPasswordController, CupertinoIcons.lock_fill, obscureText: true, suffixIcon: CupertinoIcons.eye_slash_fill ),
                buildTextField("New Password", "New Password", _newPasswordController, CupertinoIcons.lock_fill, obscureText: true),

                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        color: Colors.grey.shade300,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        focusColor: Color(0xFF3C7986),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            String name = _nameController.text;
                            String email = _emailController.text;
                            String phone = _phoneController.text;
                            String address = _addressController.text;
                            String oldPassword = _oldPasswordController.text;
                            String newPassword = _newPasswordController.text;


                            print('Name: $name, Email: $email, Phone: $phone, Address: $address, Old Password: $oldPassword, New Password: $newPassword');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Profile updated successfully! (Functionality to be implemented)')),
                            );
                          }
                        },
                        child: Text(
                          'Save Update',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
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