import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'all expense history detals.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  Map<String, Map<String, String>> friendDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriendDetails();
  }

  Future<void> _fetchFriendDetails() async {
    try {
      setState(() {
        isLoading = true;
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
            .doc(uid)
            .get();

        if (friendDoc.exists) {
          var data = friendDoc.data() as Map<String, dynamic>;
          DocumentSnapshot friendRelationDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('friends')
              .doc(uid)
              .get();

          Timestamp? addedAt = friendRelationDoc.exists
              ? friendRelationDoc.get('addedAt') as Timestamp?
              : null;

          friendDetails[uid] = {
            "name": data['name'] ?? "Unknown ($uid)",
            "profileImageUrl": data['profileImageUrl'] ?? "",
            "addedAt": addedAt?.toDate().toString() ?? "Unknown date",
          };
        } else {
          // If user doesn't exist, remove them from friends list
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('friends')
              .doc(uid)
              .delete();
          friendDetails.remove(uid);
        }
      }
    } catch (e) {
      print("Error fetching friend details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load friends: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendUid)
          .delete();

      setState(() {
        friendDetails.remove(friendUid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend removed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove friend: $e")),
      );
    }
  }

  void _showUnfriendDialog(String friendUid, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Unfriend $friendName?",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to remove $friendName from your friends list?",
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _removeFriend(friendUid);
                Navigator.pop(context);
              },
              child: Text("Unfriend", style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.grey))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.grey));
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

                return Dismissible(
                  key: Key(friendUid),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: screenWidth * 0.04),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _showUnfriendDialog(friendUid, friendName);
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExpenseHistoryDetailedScreen(
                            friendUid: friendUid,
                            showFilter: '',
                            splitId: '',
                            isReceiver: false,
                            isPayer: false,
                            sendFilter: '',
                          ),
                        ),
                      );
                    },
                    child: FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.01,
                            ),
                            leading: CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundColor: Colors.white,
                              foregroundImage: profileImageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty
                                  ? Text(
                                friendName.isNotEmpty
                                    ? friendName[0].toUpperCase()
                                    : "U",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  color: Colors.black87,
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
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Icon(
                              Icons.person,
                              color: Colors.black,
                              size: screenWidth * 0.07,
                            ),
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