import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import 'delete_account_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please sign in to continue");

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
          message: "Password updated successfully!",
          isSuccess: true,
        ));
        _clearFields();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
          message: "Error: ${e.toString()}",
          isSuccess: false,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  SnackBar _buildSnackBar({required String message, required bool isSuccess}) {
    return SnackBar(
      content: Text(message, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)), // Reduced from default
      backgroundColor: isSuccess ? Colors.teal.shade700 : Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF234567);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? Colors.grey.shade50
          : Colors.grey.shade900,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18, // Reduced from 18
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        toolbarHeight: 50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: "Account Settings",
                  icon: Icons.account_circle,
                  color: primaryColor,
                  child: _buildPasswordForm(theme),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  title: "Account Actions",
                  icon: Icons.settings,
                  color: primaryColor,
                  child: _buildDeleteAccountTile(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18, // Reduced from 22
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Change Password",
            style: GoogleFonts.poppins(
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _currentPasswordController,
            label: "Current Password",
            icon: Icons.lock,
            obscureText: true,
            validator: (value) => value!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _newPasswordController,
            label: "New Password",
            icon: Icons.lock_open,
            obscureText: true,
            validator: (value) => value!.isEmpty
                ? "Required"
                : value.length < 6
                ? "Minimum 6 characters"
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Confirm Password",
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) => value!.isEmpty
                ? "Required"
                : value != _newPasswordController.text
                ? "Passwords don't match"
                : null,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF234567),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                  : Text(
                "Update Password",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Reduced from default
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountTile(ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.delete, color: Colors.black, size: 28),
      title: Text(
        "Delete Account",
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500), // Reduced from 16
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal.shade700, size: 18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal.shade700),
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12), // Reduced from default
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade700, width: 1.5),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14), // Explicitly set smaller size
      validator: validator,
    );
  }
}