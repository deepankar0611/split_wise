import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'frind split screen.dart';
 // Ensure this import is correct

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  Map<String, Map<String, String>> friendDetails = {}; // Cache friend name and profile image URL

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
          "profileImageUrl": data!.containsKey('profileImageUrl') ? data!['profileImageUrl'] : "",
        };
      }
      if (mounted) setState(() {});
    } catch (e) {
      print("Error fetching friend details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "My Friends",
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
            .collection('users')
            .doc(userId)
            .collection('friends')
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
                "No friends added yet.",
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600),
              ),
            );
          }

          var friends = snapshot.data!.docs;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                String friendUid = friends[index].id;
                String friendName = friendDetails[friendUid]?["name"] ?? "Loading...";
                String profileImageUrl = friendDetails[friendUid]?["profileImageUrl"] ?? "";

                return GestureDetector(
                  onTap: () {
                    print("Tapping on friend: $friendName (UID: $friendUid)"); // Debug print
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendSplitsScreen(friendUid: friendUid),
                      ),
                    ).then((value) {
                      print("Returned from FriendSplitsScreen"); // Debug return
                    }).catchError((error) {
                      print("Navigation error: $error"); // Debug errors
                    });
                  },
                  child: FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      shadowColor: Colors.teal.withOpacity(0.3),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.teal.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
                          leading: CircleAvatar(
                            radius: screenWidth * 0.06,
                            backgroundColor: Colors.teal.shade100,
                            foregroundImage: profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profileImageUrl) // Use CachedNetworkImageProvider for foreground
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Icon(
                            Icons.person,
                            color: Colors.teal.shade700,
                            size: screenWidth * 0.07,
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