import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => "");

// StreamProvider for fetching users
final usersProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, name) {
  String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  if (name.isEmpty) {
    return const Stream.empty();
  }

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
});



