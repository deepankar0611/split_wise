import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UPIPaymentScreen extends StatefulWidget {
  final String splitId;
  final double amountToPay; // Still received as double from SplitDetailScreen

  const UPIPaymentScreen({super.key, required this.splitId, required this.amountToPay});

  @override
  State<UPIPaymentScreen> createState() => _UPIPaymentScreenState();
}

class _UPIPaymentScreenState extends State<UPIPaymentScreen> {
  final TextEditingController _upiController = TextEditingController(text: "7479519946@pytes");
  bool _isVerifying = false;
  bool _isValidUpi = false;
  String? _errorMessage;

  Future<void> _verifyUpiId(String upiId) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _isValidUpi = false;
    });

    RegExp upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    if (upiRegex.hasMatch(upiId)) {
      setState(() {
        _isValidUpi = true;
      });
    } else {
      setState(() {
        _isValidUpi = false;
        _errorMessage = "Invalid UPI ID format. Example: 7479519946@pytes";
      });
    }

    setState(() {
      _isVerifying = false;
    });
  }

  Future<void> _sendPaymentRequest() async {
    if (!_isValidUpi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please verify the UPI ID first", style: GoogleFonts.poppins())),
      );
      return;
    }

    String upiId = _upiController.text.trim();
    // Convert amount to integer rupees (truncate decimals)
    int amountInRupees = widget.amountToPay.floor(); // e.g., 10.75 becomes 10
    String transactionNote = "Payment for Split ${widget.splitId}";
    String senderName = await _getUserName(FirebaseAuth.instance.currentUser!.uid);

    // Construct UPI URI with amount as integer rupees
    String upiUri = Uri.encodeFull(
      "upi://pay?pa=$upiId&pn=$senderName&am=$amountInRupees&cu=INR&tn=$transactionNote",
    );

    try {
      bool launched = await launchUrl(Uri.parse(upiUri), mode: LaunchMode.externalApplication);
      if (launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment request sent to $upiId for ₹$amountInRupees!", style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade600,
          ),
        );
        // Log to Firestore for testing
        await FirebaseFirestore.instance
            .collection('splits')
            .doc(widget.splitId)
            .collection('transactions')
            .add({
          'from': FirebaseAuth.instance.currentUser!.uid,
          'to': upiId,
          'amount': amountInRupees, // Store as integer
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'initiated',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No UPI app found to handle this request", style: GoogleFonts.poppins()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error launching UPI app: $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<String> _getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (userDoc.data() as Map<String, dynamic>?)?['name'] ?? "User";
    } catch (e) {
      return "User";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Display amount as integer in UI
    int displayAmount = widget.amountToPay.floor();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF234567),
        title: Text("UPI Payment", style: GoogleFonts.poppins(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pay ₹$displayAmount",
              style: GoogleFonts.poppins(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02),
            TextField(
              controller: _upiController,
              decoration: InputDecoration(
                labelText: "Receiver UPI ID",
                hintText: "e.g., 7479519946@pytes",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_isVerifying ? Icons.hourglass_empty : LucideIcons.check),
                  onPressed: () => _verifyUpiId(_upiController.text.trim()),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red)),
              ),
            if (_isValidUpi)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text("UPI ID is valid!", style: GoogleFonts.poppins(color: Colors.green)),
              ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton(
              onPressed: _sendPaymentRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF234567),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              ),
              child: Center(
                child: Text(
                  "Send Payment Request",
                  style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Note: For testing, confirm or cancel in your UPI app. Amount is in integer rupees.",
              style: GoogleFonts.poppins(fontSize: screenWidth * 0.035, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}