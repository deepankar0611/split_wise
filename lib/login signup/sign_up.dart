import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Helper/local.dart';
import 'login_screen.dart';


class SignUpPage extends StatefulWidget {
  SignUpPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> signUpUser(String email, String password, String name) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Validate inputs before proceeding
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all fields")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        String uid = user.uid;

        // Store user data in Firestore with UID as document ID
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send email verification
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          print("Verification email sent!");

          // Show alert dialog
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Email Verification"),
                  content: Text("Please check your email and verify your account."),
                  actions: [
                    TextButton(
                      child: Text("OK"),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        ); // Navigate to LoginPage
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            print("Widget not mounted, dialog not shown");
          }
        }
      } else {
        print("User is null after sign-up");
      }
    } catch (e) {
      print("Error during sign-up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign Up Failed: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Reduced vertical padding
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(Icons.keyboard_arrow_left, color: Colors.black, size: 20), // Reduced icon size
            ),
            Text('Back',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)) // Adjusted font size
          ],
        ),
      ),
    );
  }

  Widget _entryField(String title, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6), // Further reduced vertical margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Slightly reduced font size
          ),
          SizedBox(height: 4), // Further reduced SizedBox height
          TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Color(0xfff3f3f4),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Further reduced padding
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () {
        signUpUser(_emailController.text.trim(), _passwordController.text.trim(), _usernameController.text.trim());
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7, // Further reduced width (you can adjust this)
        padding: EdgeInsets.symmetric(vertical: 12), // Further reduced vertical padding
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.shade200,
              offset: Offset(2, 4),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A2E39), // Brighter green for neon effect
              Color(0xFF1A2E39), // Brighter blue for neon effect
            ],
            stops: [0.0, 1.0], // Adjust stops for desired transition
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : Text(
          'Register Now',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold), // Further adjusted style
        ),
      ),
    );
  }

  Widget _loginAccountLabel() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 7), // Further reduced vertical margin
        padding: EdgeInsets.all(7), // Further reduced padding
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Already have an account ?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), // Further adjusted font size
            ),
            SizedBox(width: 5),
            Text(
              'Login',
              style: TextStyle(
                  color: Color(0xFF1A2E39),
                  fontSize: 12,
                  fontWeight: FontWeight.w600), // Further adjusted font size
            ),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 's',
        style: TextStyle(
          fontSize: 28, // Slightly reduced title font size
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A2E39),
        ),
        children: [
          TextSpan(
            text: 'pl',
            style: TextStyle(color: Color(0xFF3C7986), fontSize: 28), // Slightly reduced title font size
          ),
          TextSpan(
            text: 'it-',
            style: TextStyle(color: Color(0xFF1A2E39), fontSize: 28), // Slightly reduced title font size
          ),
          TextSpan(
            text: 'up',
            style: TextStyle(color: Color(0xFF3C7986), fontSize: 28), // Slightly reduced title font size
          ),
        ],
      ),
    );
  }

  Widget _emailPasswordWidget() {
    return Column(
      children: <Widget>[
        _entryField("Username", _usernameController),
        _entryField("Email id", _emailController),
        _entryField("Password", _passwordController, isPassword: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -MediaQuery.of(context).size.height * .15,
            right: -MediaQuery.of(context).size.width * .4,
            child: BezierContainer(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: height * .10), // Further adjusted top spacing
                _title(),
                SizedBox(height: 25), // Further reduced spacing
                _emailPasswordWidget(),
                SizedBox(height: 8), // Further reduced spacing
                _submitButton(),
                SizedBox(height: 25), // Further reduced spacing
                _loginAccountLabel(),
              ],
            ),
          ),
          Positioned(top: 40, left: 0, child: _backButton()),
        ],
      ),
    );
  }
}