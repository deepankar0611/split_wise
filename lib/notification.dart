import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:split_wise/home_screen.dart';

class Notificationn extends StatefulWidget {
  const Notificationn({super.key});

  @override
  State<Notificationn> createState() => _NotificationnState();
}

class _NotificationnState extends State<Notificationn> {

  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  /// Fetch friend requests
  Stream<QuerySnapshot<Map<String, dynamic>>> getFriendRequests() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('friend_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Accept Friend Request
  Future<void> acceptFriendRequest(String friendUid) async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;

    var currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    var friendUserRef = FirebaseFirestore.instance.collection('users').doc(friendUid);

    // Fetch friend's data
    var friendDoc = await friendUserRef.get();
    if (!friendDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User data not found!")));
      return;
    }

    var friendData = friendDoc.data()!;
    String friendName = friendData['name'] ?? "Unknown";
    String friendEmail = friendData['email'] ?? "No email";
    String friendProfilePic = friendData['profilePic'] ?? "";

    // Add to current user's friend list with full details
    await currentUserRef.collection('friends').doc(friendUid).set({
      "uid": friendUid,
      "name": friendName,
      "email": friendEmail,
      "profilePic": friendProfilePic,
      "addedAt": FieldValue.serverTimestamp(),
    });

    // Fetch current user’s data
    var currentUserDoc = await currentUserRef.get();
    if (!currentUserDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your data not found!")));
      return;
    }

    var currentUserData = currentUserDoc.data()!;
    String currentUserName = currentUserData['name'] ?? "Unknown";
    String currentUserEmail = currentUserData['email'] ?? "No email";
    String currentUserProfilePic = currentUserData['profilePic'] ?? "";

    // Add current user to friend's friend list with full details
    await friendUserRef.collection('friends').doc(currentUid).set({
      "uid": currentUid,
      "name": currentUserName,
      "email": currentUserEmail,
      "profilePic": currentUserProfilePic,
      "addedAt": FieldValue.serverTimestamp(),
    });

    // Remove the request
    await currentUserRef.collection('friend_requests').doc(friendUid).delete();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request accepted!")));
  }


  /// Reject Friend Request
  Future<void> rejectFriendRequest(String friendUid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('friend_requests')
        .doc(friendUid)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request rejected!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getFriendRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No new friend requests"));
            }

            return ListView(
              children: snapshot.data!.docs.map((doc) {
                var requestData = doc.data();
                String senderUid = requestData['fromUid'];

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection('users').doc(senderUid).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const SizedBox.shrink(); // Hide if user doesn't exist
                    }

                    var userData = userSnapshot.data!.data()!;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(userData['name']?[0] ?? "?"), // First letter of name
                        ),
                        title: Text(userData['name'] ?? "Unknown"),
                        subtitle: Text(userData['email'] ?? "No email"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => acceptFriendRequest(senderUid),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => rejectFriendRequest(senderUid),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
