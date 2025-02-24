import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'all expense history detals.dart'; // Ensure this import matches your file name

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  Map<String, Map<String, String>> friendDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchFriendDetails();
  }

  Future<void> _fetchFriendDetails() async {
    try {
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      List<String> friendUids = friendsSnapshot.docs.map((doc) => doc.id).toList();

      for (String uid in friendUids) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        var data = userDoc.data() as Map<String, dynamic>?;
        friendDetails[uid] = {
          "name": data?['name'] ?? "Unknown ($uid)",
          "profileImageUrl": data?.containsKey('profileImageUrl') ?? false ? data!['profileImageUrl'] : "",
        };
      }
      if (mounted) setState(() {});
    } catch (e) {
      print("Error fetching friend details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.08), // 8% of screen height
        child: AppBar(
          title: Text(
            "My Friends",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.055, // Responsive font size
            ),
          ),
          backgroundColor: const Color(0xFF234567),
          elevation: 4,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.06),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No friends added yet.",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          }

          var friends = snapshot.data!.docs;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, // 4% of screen width
              vertical: screenHeight * 0.02, // 2% of screen height
            ),
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                String friendUid = friends[index].id;
                String friendName = friendDetails[friendUid]?["name"] ?? "Loading...";
                String profileImageUrl = friendDetails[friendUid]?["profileImageUrl"] ?? "";

                return GestureDetector(
                  onTap: () {
                    print("Tapping on friend: $friendName (UID: $friendUid)");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpenseHistoryDetailedScreen(
                          friendUid: friendUid,
                          showFilter: '',
                          splitId: '',
                          isReceiver: false,
                          isPayer: false,
                        ),
                      ),
                    ).then((value) {
                      print("Returned from ExpenseHistoryDetailedScreen");
                    }).catchError((error) {
                      print("Navigation error: $error");
                    });
                  },
                  child: FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
                      elevation: screenWidth * 0.015, // Responsive elevation
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      shadowColor: Colors.teal.withOpacity(0.3),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.teal.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          leading: CircleAvatar(
                            radius: screenWidth * 0.06, // 6% of screen width
                            backgroundColor: Colors.teal.shade100,
                            foregroundImage: profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Text(
                              friendName.isNotEmpty ? friendName[0].toUpperCase() : "U",
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                color: Colors.teal.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
                          title: Text(
                            friendName,
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.045, // Responsive font size
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Icon(
                            Icons.person,
                            color: Colors.teal.shade700,
                            size: screenWidth * 0.07, // Responsive icon size
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}