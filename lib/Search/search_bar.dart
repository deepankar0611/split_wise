import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  Stream<List<Map<String, dynamic>>> getUsersByName(String name) {
    if (name.isEmpty) return Stream.value([]);
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => doc.data())
          .where((user) =>
      user['uid'] != currentUserUid &&
          user['name'].toString().toLowerCase().contains(name.toLowerCase()))
          .toList(),
    );
  }

  Future<bool> isAlreadyFriend(String friendUid) async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final friendDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('friends')
        .doc(friendUid)
        .get();
    return friendDoc.exists;
  }

  Future<void> sendFriendRequest(String friendUid) async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(friendUid)
        .collection('friend_requests')
        .doc(currentUserUid)
        .set({
      "fromUid": currentUserUid,
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Friend request sent!", style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Find Friends",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A3C6D),
                Color(0xFF0A2A4D),
                Color(0xFF1A3C6D),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1A3C6D).withOpacity(0.5),
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
        ),
        toolbarHeight: screenWidth * 0.15,
      ),
      body: Stack(
        children: [
          // Centered Image
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/logo/123.jpg',
                fit: BoxFit.cover,
                height: screenHeight * 0.5,
                width: screenWidth,
              ),
            ),
          ),
          // Text on top of the image
          Positioned(
            top: screenHeight * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Find Your Friends",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  children: [
                    Material(
                      elevation: screenWidth * 0.015,
                      shadowColor: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          hintText: "Search by name...",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.04,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.teal.shade700, size: screenWidth * 0.06),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        ),
                        style: GoogleFonts.poppins(fontSize: screenWidth * 0.04),
                        onChanged: (value) => setState(() => searchQuery = value.trim()),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Expanded(
                      child: searchQuery.isNotEmpty
                          ? StreamBuilder<List<Map<String, dynamic>>>(
                        stream: getUsersByName(searchQuery),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: Colors.teal.shade700));
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Error: ${snapshot.error}",
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                "No users found",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final userData = snapshot.data![index];
                              return FutureBuilder<bool>(
                                future: isAlreadyFriend(userData['uid']),
                                builder: (context, isFriendSnapshot) {
                                  if (isFriendSnapshot.connectionState == ConnectionState.waiting) {
                                    return SizedBox.shrink();
                                  }

                                  bool isFriend = isFriendSnapshot.data ?? false;

                                  return Card(
                                    elevation: screenWidth * 0.015,
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
                                          radius: screenWidth * 0.06,
                                          backgroundImage: userData['profileImageUrl'] != null &&
                                              userData['profileImageUrl'].isNotEmpty
                                              ? NetworkImage(userData['profileImageUrl'])
                                              : null,
                                          backgroundColor: Colors.teal.shade100,
                                          child: userData['profileImageUrl'] == null ||
                                              userData['profileImageUrl'].isEmpty
                                              ? Text(
                                            userData['name']?[0].toUpperCase() ?? "?",
                                            style: GoogleFonts.poppins(
                                              fontSize: screenWidth * 0.05,
                                              color: Colors.teal.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                              : null,
                                        ),
                                        title: Text(
                                          userData['name'] ?? "Unknown",
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        subtitle: Text(
                                          userData['email'] ?? "No email",
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        trailing: isFriend
                                            ? Chip(
                                          label: Text(
                                            "Friend",
                                            style: GoogleFonts.poppins(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.green.shade700,
                                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                        )
                                            : ElevatedButton(
                                          onPressed: () => sendFriendRequest(userData['uid']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF234567),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.04,
                                              vertical: screenHeight * 0.015,
                                            ),
                                          ),
                                          child: Text(
                                            "Add Friend",
                                            style: GoogleFonts.poppins(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      )
                          : Center(
                        child: Text(
                          "Search for a user by name",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}