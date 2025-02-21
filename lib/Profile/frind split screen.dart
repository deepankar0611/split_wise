import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class FriendSplitsScreen extends StatefulWidget {
  final String friendUid;

  const FriendSplitsScreen({super.key, required this.friendUid});

  @override
  State<FriendSplitsScreen> createState() => _FriendSplitsScreenState();
}

class _FriendSplitsScreenState extends State<FriendSplitsScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Splits with Friend",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF234567),
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('splits')
            .where('participants', arrayContainsAny: [userId, widget.friendUid])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: Colors.grey)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No splits with this friend yet.",
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600),
              ),
            );
          }

          var splits = snapshot.data!.docs;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recent Splits",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                // Constrain the height of the horizontal ListView to prevent overflow
                SizedBox(
                  height: 120, // Fixed height to match "Recent Priority Bills" cards
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: splits.length,
                    itemBuilder: (context, index) {
                      var splitDoc = splits[index];
                      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
                      Map<String, dynamic> paidBy = splitData['paidBy'] as Map<String, dynamic>? ?? {};
                      double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
                      int participantCount = (splitData['participants'] as List<dynamic>?)?.length ?? 1;
                      double userPaidAmount = (paidBy[userId] as num?)?.toDouble() ?? 0.0;
                      double friendPaidAmount = (paidBy[widget.friendUid] as num?)?.toDouble() ?? 0.0;
                      double sharePerPerson = totalAmount / participantCount;
                      double yourNet = sharePerPerson - userPaidAmount;
                      double friendNet = sharePerPerson - friendPaidAmount;
                      double netAmount = yourNet - friendNet; // Positive if you owe, negative if friend owes
                      String displayAmount = netAmount >= 0
                          ? "-₹${netAmount.toStringAsFixed(2)}"
                          : "+₹${(-netAmount).toStringAsFixed(2)}";

                      return FadeInUp(
                        delay: Duration(milliseconds: 100 * index), // Optional animation for a smooth entrance
                        child: _buildSplitCard(
                          screenWidth,
                          splitData['description'] ?? 'Unknown Split',
                          (splitData['createdAt'] as Timestamp?)?.toDate().toString() ?? DateTime.now().toString(),
                          displayAmount,
                          Colors.blueAccent,
                          netAmount.abs() < 0.01, // Settled if net amount is effectively zero
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSplitCard(double width, String title, String date, String amount, Color color, bool settled) {
    DateTime createdAtDate = DateTime.parse(date);
    Duration difference = DateTime.now().difference(createdAtDate);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      timeAgo = "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      timeAgo = "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      timeAgo = "Just now";
    }

    return Container(
      width: 140, // Matches the width in your screenshot
      height: 100, // Fixed height to match "Recent Priority Bills" cards
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Changed to white to match your screenshot
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            settled ? "Settled" : timeAgo,
            style: TextStyle(
              color: settled ? Colors.green[600] : Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (!settled)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                amount,
                style: TextStyle(
                  color: amount.startsWith('+') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }
}