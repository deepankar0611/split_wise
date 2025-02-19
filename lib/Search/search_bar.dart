import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  Stream<List<Map<String, dynamic>>> getUsersByName(String name) {
    if (name.isEmpty) return const Stream.empty();

    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance.collection('users').snapshots().map(
          (snapshot) {
        return snapshot.docs
            .map((doc) => doc.data())
            .where((user) =>
        user['uid'] != currentUserUid &&
            user['name']
                .toString()
                .toLowerCase()
                .contains(name.toLowerCase()))
            .toList();
      },
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
        content: const Text("Friend request sent!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Find Friends",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'YourPreferredFont', // Replace with your desired font
          ),
        ),
        backgroundColor: const Color(0xFF234567),
        elevation: 4, // Adds shadow for depth
        centerTitle: true, // Centers the title
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ), // Rounded bottom corners
        toolbarHeight: 50, // Increase height for more visual impact
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by name...",
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => setState(() => searchQuery = value.trim()),
              ),
            ),
            const SizedBox(height: 20),
            searchQuery.isNotEmpty
                ? StreamBuilder<List<Map<String, dynamic>>>(
              stream: getUsersByName(searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final userData = snapshot.data![index];
                      return FutureBuilder<bool>(
                        future: isAlreadyFriend(userData['uid']),
                        builder: (context, isFriendSnapshot) {
                          if (isFriendSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }

                          bool isFriend = isFriendSnapshot.data ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey.shade100,
                                child: Text(
                                  userData['name']?[0] ?? "?",
                                  style: const TextStyle(color: Colors.blueGrey),
                                ),
                              ),
                              title: Text(
                                userData['name'] ?? "Unknown",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Text(userData['email'] ?? "No email"),
                              trailing: isFriend
                                  ? const Chip(
                                label: Text("Friend"),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                                  : ElevatedButton(
                                onPressed: () =>
                                    sendFriendRequest(userData['uid']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF234567),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Add Friend"),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            )
                : const Center(
              child: Text(
                "Search for a user by name",
                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
