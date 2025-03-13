import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Helper/local.dart';
 // Assuming this file exists

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Password reset email sent! Please check your inbox.",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Go back to the login screen after success
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Error sending reset email: $e",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _entryField(String title) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Color(0xfff3f3f4),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _resetPassword,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8, // Slightly reduced width
        padding: EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), // More rounded corners
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.shade200,
              offset: Offset(2, 4),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF3C7986), Color(0xFF1A2E39)], // Keeping the same gradient for consistency
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : Text(
          'Send Reset Email',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold), // Slightly adjusted style
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3C7986), Color(0xFF1A2E39)],
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 's',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A2E39),
        ),
        children: [
          TextSpan(
            text: 'pl',
            style: TextStyle(
              foreground: Paint()
                ..shader = gradient.createShader(Rect.fromLTWH(0.0, 0.0, 80.0, 30.0)), // Adjust width and height as needed
              fontSize: 30,
            ),
          ),
          TextSpan(
            text: 'it',
            style: TextStyle(color: Color(0xFF1A2E39), fontSize: 30),
          ),
          TextSpan(
            text: 'up',
            style: TextStyle(
              foreground: Paint()
                ..shader = gradient.createShader(Rect.fromLTWH(0.0, 0.0, 80.0, 30.0)), // Adjust width and height as needed
              fontSize: 30,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -height * .15,
            right: -MediaQuery.of(context).size.width * .4,
            child: BezierContainer(), // Using the BezierContainer for background
          ),
          SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: height * 0.15), // Added top spacing when using SingleChildScrollView
                  _title(context), // Using the same title style
                  SizedBox(height: 40),
                  
                  SizedBox(height: 20),
                  _entryField("Email id"),
                  SizedBox(height: 20),
                  _submitButton(),
                  SizedBox(height: 30),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.arrow_back, color: Colors.black54),
                        SizedBox(width: 5),
                        Text(
                          'Back to Login',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(height: 30), // Added bottom spacing for SingleChildScrollView
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}