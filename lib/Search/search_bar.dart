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

  /// Fetch users dynamically and filter case-insensitively
  Stream<List<Map<String, dynamic>>> getUsersByName(String name) {
    if (name.isEmpty) {
      return const Stream.empty();
    }

    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance.collection('users').snapshots().map(
          (snapshot) {
        return snapshot.docs
            .map((doc) => doc.data())
            .where((user) =>
        user['uid'] != currentUserUid && // Exclude current user
            user['name']
                .toString()
                .toLowerCase()
                .contains(name.toLowerCase()))
            .toList();
      },
    );
  }

  /// Send a friend request
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
      const SnackBar(content: Text("Friend request sent!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Friends"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Enter Name to search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
            const SizedBox(height: 20),

            // User List
            searchQuery.isNotEmpty
                ? StreamBuilder<List<Map<String, dynamic>>>(
              stream: getUsersByName(searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("User not found"));
                }

                return Expanded(
                  child: ListView(
                    children: snapshot.data!.map((userData) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(userData['name']?[0] ?? "?"), // First letter of name
                          ),
                          title: Text(userData['name'] ?? "Unknown"),
                          subtitle: Text(userData['email'] ?? "No email"),
                          trailing: ElevatedButton(
                            onPressed: () => sendFriendRequest(userData['uid']),
                            child: const Text("Add Friend"),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            )
                : const Center(child: Text("Search for a user by name")),
          ],
        ),
      ),
    );
  }
}
