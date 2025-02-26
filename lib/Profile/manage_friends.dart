import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'all expense history detals.dart'; // Ensure this matches your file name

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  Map<String, Map<String, String>> friendDetails = {};
  bool isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _fetchFriendDetails();
  }

  Future<void> _fetchFriendDetails() async {
    try {
      setState(() {
        isLoading = true; // Show loading initially
      });

      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      List<String> friendUids = friendsSnapshot.docs.map((doc) => doc.id).toList();

      for (String uid in friendUids) {
        DocumentSnapshot friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .doc(uid)
            .get();

        if (friendDoc.exists) {
          Timestamp? addedAt = friendDoc.get('addedAt') as Timestamp?;
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (userDoc.exists) {
            var data = userDoc.data() as Map<String, dynamic>?;
            friendDetails[uid] = {
              "name": data?['name'] ?? "Unknown ($uid)",
              "profileImageUrl": data?['profileImageUrl'] ?? "",
              "addedAt": addedAt?.toDate().toString() ?? "Unknown date",
            };
          } else {
            friendDetails[uid] = {
              "name": "User Not Found ($uid)",
              "profileImageUrl": "",
              "addedAt": "Unknown date",
            };
          }
        } else {
          friendDetails[uid] = {
            "name": "Friend Not Found ($uid)",
            "profileImageUrl": "",
            "addedAt": "Unknown date",
          };
        }
      }
    } catch (e) {
      print("Error fetching friend details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load friends: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Hide loading when done
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.06),
        child: AppBar(
          title: Text(
            "My Friends",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.045,
            ),
          ),
          backgroundColor: const Color(0xFF234567), // Kept the AppBar color as it is not teal
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
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.grey)) // Changed loading indicator to grey for visibility on white
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.grey)); // Changed loading indicator to grey for visibility on white
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
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
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
                          isPayer: false, sendFilter: '',
                        ),
                      ),
                    );
                  },
                  child: FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
                      elevation: 0, // Removed shadow for white background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      shadowColor: Colors.transparent, // Removed shadow for white background
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Changed container background to white
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          leading: CircleAvatar(
                            radius: screenWidth * 0.06,
                            backgroundColor: Colors.white, // Changed CircleAvatar background to white
                            foregroundImage: profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Text(
                              friendName.isNotEmpty ? friendName[0].toUpperCase() : "U",
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                color: Colors.black87, // Changed text color in CircleAvatar to black
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
                          title: Text(
                            friendName,
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87, // Changed title text color to black
                            ),
                          ),
                          trailing: Icon(
                            Icons.person,
                            color: Colors.black, // Kept the icon color as teal
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