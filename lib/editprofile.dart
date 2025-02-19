import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? _profileImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        elevation: 0.8,
        shadowColor: Colors.grey.shade300,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: CupertinoColors.label.resolveFrom(context)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CupertinoColors.systemGroupedBackground.resolveFrom(context),
              CupertinoColors.systemBackground.resolveFrom(context),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: <Widget>[
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            spreadRadius: 3,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _profileImage != null
                            ? AssetImage(_profileImage!) as ImageProvider<Object>?
                            : NetworkImage('https://via.placeholder.com/150') ,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
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
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(CupertinoIcons.pencil, color: CupertinoColors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              buildSectionHeader('Personal Info'),
              buildProfileTile('Josh Smith', CupertinoIcons.person_fill),
              buildSectionHeader('Account Settings'),
              buildProfileTile('Change Password', CupertinoIcons.lock_shield_fill),
              buildProfileTile('Change Email Address', CupertinoIcons.mail_solid),

              SizedBox(height: 30),
              CupertinoButton.filled(
                // Changed button color here
                focusColor: Color(0xFF3C7986),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String name = _nameController.text;
                    String email = _emailController.text;
                    String password = _passwordController.text;

                    print('Name: $name, Email: $email, Password: $password');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully! (Functionality to be implemented)')),
                    );
                  }
                },
                child: Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 14), // Same text style as TextFormField
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: CupertinoColors.label.resolveFrom(context),
          ),
          children: <TextSpan>[
            TextSpan(text: title, style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget buildProfileTile(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            spreadRadius: 0.5,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: CupertinoColors.activeBlue),
        title: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(
              color: CupertinoColors.black,
              fontSize: 15,
            ),
            children: <TextSpan>[
              TextSpan(text: title, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        trailing: Icon(CupertinoIcons.forward, color: CupertinoColors.inactiveGray),
        onTap: () {
          // TODO: Implement navigation or action for each tile
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title functionality to be implemented')),
          );
        },
      ),
    );
  }
}