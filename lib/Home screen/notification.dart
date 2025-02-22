import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:split_wise/Home%20screen/split%20details.dart';
import 'package:split_wise/Profile/all%20expense%20history%20detals.dart' as ExpenseHistory;

class Notificationn extends StatefulWidget {
  const Notificationn({super.key});

  @override
  State<Notificationn> createState() => _NotificationnState();
}

class _NotificationnState extends State<Notificationn> {
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _showBanner = false;
  String? _bannerTitle;
  String? _bannerBody;
  String? _bannerSplitId;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupNotificationListeners();
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          goToExpenseHistoryDetail(response.payload!);
        }
      },
    );
  }

  void _setupNotificationListeners() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('friend_requests')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data()!;
          _showNotification(
            "Friend Request",
            "${userNames[data['fromUid']] ?? 'Someone'} sent a friend request",
            change.doc.id,
          );
        }
      }
    });

    FirebaseFirestore.instance
        .collectionGroup('reminders')
        .where('participants', arrayContains: currentUserUid)
        .where('sentBy', isNotEqualTo: currentUserUid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data()!;
          String splitId = data['splitId'] ?? change.doc.reference.parent.parent!.id;
          FirebaseFirestore.instance.collection('splits').doc(splitId).get().then((splitDoc) {
            String description = splitDoc.data()?['description'] ?? 'No description';
            _showNotification(
              "${userNames[data['sentBy']] ?? 'Someone'} sent a reminder",
              "Split details of '$description'",
              splitId,
            );
          });
        }
      }
    });
  }

  Future<void> _showNotification(String title, String body, String payload) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'notification_channel',
      'Notifications',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    if (mounted) {
      setState(() {
        _showBanner = true;
        _bannerTitle = title;
        _bannerBody = body;
        _bannerSplitId = payload;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showBanner = false);
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFriendRequests() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('friend_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSplitReminders() {
    return FirebaseFirestore.instance
        .collectionGroup('reminders')
        .where('participants', arrayContains: currentUserUid)
        .where('sentBy', isNotEqualTo: currentUserUid)
        .orderBy('sentBy')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> acceptFriendRequest(String friendUid) async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;
    var db = FirebaseFirestore.instance;

    var currentUserRef = db.collection('users').doc(currentUid);
    var friendUserRef = db.collection('users').doc(friendUid);

    try {
      var friendDoc = await friendUserRef.get();
      if (!friendDoc.exists) {
        _showSnackBar("User data not found!");
        return;
      }

      var friendData = friendDoc.data() as Map<String, dynamic>;
      String friendName = friendData['name'] ?? "Unknown";
      String friendEmail = friendData['email'] ?? "No email";
      String friendProfilePic = friendData['profilePic'] ?? "";

      await currentUserRef.collection('friends').doc(friendUid).set({
        "uid": friendUid,
        "name": friendName,
        "email": friendEmail,
        "profilePic": friendProfilePic,
        "addedAt": FieldValue.serverTimestamp(),
      });

      var currentUserDoc = await currentUserRef.get();
      if (!currentUserDoc.exists) {
        _showSnackBar("Your data not found!");
        return;
      }

      var currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      String currentUserName = currentUserData['name'] ?? "Unknown";
      String currentUserEmail = currentUserData['email'] ?? "No email";
      String currentUserProfilePic = currentUserData['profilePic'] ?? "";

      await friendUserRef.collection('friends').doc(currentUid).set({
        "uid": currentUid,
        "name": currentUserName,
        "email": currentUserEmail,
        "profilePic": currentUserProfilePic,
        "addedAt": FieldValue.serverTimestamp(),
      });

      await currentUserRef.collection('friend_requests').doc(friendUid).delete();
      _showSnackBar("Friend request accepted!");
      setState(() {});
    } catch (e) {
      _showSnackBar("Error accepting friend request: $e");
    }
  }

  Future<void> rejectFriendRequest(String friendUid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('friend_requests')
          .doc(friendUid)
          .delete();
      _showSnackBar("Friend request rejected!");
      setState(() {});
    } catch (e) {
      _showSnackBar("Error rejecting friend request: $e");
    }
  }

  Future<void> dismissReminder(String splitId, String reminderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('splits')
          .doc(splitId)
          .collection('reminders')
          .doc(reminderId)
          .update({
        'dismissedBy': FieldValue.arrayUnion([currentUserUid]),
      });
      _showSnackBar("Reminder dismissed");
      setState(() {});
    } catch (e) {
      _showSnackBar("Error dismissing reminder: $e");
    }
  }

  void goToExpenseHistoryDetail(String splitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseHistory.ExpenseHistoryDetailedScreen(
          splitId: splitId,
          friendUid: null,
          category: null,
          isPayer: null,
          isReceiver: null,
          showFilter: splitId, // Adjust based on your ExpenseHistoryDetailedScreen requirements
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins())),
    );
  }

  Map<String, String> userNames = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF234567),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getFriendRequests(),
              builder: (context, friendSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: getSplitReminders(),
                  builder: (context, reminderSnapshot) {
                    if (friendSnapshot.hasError || reminderSnapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${friendSnapshot.error ?? reminderSnapshot.error}",
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }
                    if (friendSnapshot.connectionState == ConnectionState.waiting ||
                        reminderSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<Map<String, dynamic>> allNotifications = [];

                    if (friendSnapshot.hasData && friendSnapshot.data!.docs.isNotEmpty) {
                      allNotifications.addAll(friendSnapshot.data!.docs.map((doc) {
                        var data = doc.data();
                        userNames[data['fromUid']] = "Unknown";
                        return {
                          'type': 'friend_request',
                          'data': data,
                          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                          'id': doc.id,
                        };
                      }));
                    }

                    if (reminderSnapshot.hasData && reminderSnapshot.data!.docs.isNotEmpty) {
                      allNotifications.addAll(reminderSnapshot.data!.docs.map((doc) {
                        var data = doc.data();
                        String splitId = data['splitId'] ?? doc.reference.parent.parent!.id;
                        userNames[data['sentBy']] = "Unknown";
                        return {
                          'type': 'split_reminder',
                          'data': data,
                          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                          'id': doc.id,
                          'splitId': splitId,
                        };
                      }));
                    }

                    allNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

                    if (allNotifications.isEmpty) {
                      return Center(child: Text("No notifications", style: GoogleFonts.poppins()));
                    }

                    return ListView.builder(
                      itemCount: allNotifications.length,
                      itemBuilder: (context, index) {
                        var notification = allNotifications[index];
                        if (notification['type'] == 'friend_request') {
                          String senderUid = notification['data']['fromUid'];
                          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance.collection('users').doc(senderUid).get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.hasError) {
                                return Text("User Error: ${userSnapshot.error}", style: GoogleFonts.poppins());
                              }
                              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }
                              var userData = userSnapshot.data!.data()!;
                              userNames[senderUid] = userData['name'] ?? "Unknown";
                              String senderName = userNames[senderUid]!;
                              String formattedDate = DateFormat('dd MMM, hh:mm a')
                                  .format(notification['timestamp']);
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF234567),
                                    child: Text(senderName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text("$senderName sent a friend request",
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Text("Sent: $formattedDate",
                                      style: GoogleFonts.poppins(color: Colors.grey[600])),
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
                        } else if (notification['type'] == 'split_reminder') {
                          String senderUid = notification['data']['sentBy'];
                          String splitId = notification['splitId'];
                          String reminderId = notification['id'];
                          List<dynamic> dismissedBy = notification['data']['dismissedBy'] ?? [];

                          if (dismissedBy.contains(currentUserUid)) return const SizedBox.shrink();

                          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance.collection('users').doc(senderUid).get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.hasError) {
                                return Text("User Error: ${userSnapshot.error}", style: GoogleFonts.poppins());
                              }
                              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }
                              var userData = userSnapshot.data!.data()!;
                              userNames[senderUid] = userData['name'] ?? "Unknown";
                              String senderName = userNames[senderUid]!;
                              String formattedDate = DateFormat('dd MMM, hh:mm a')
                                  .format(notification['timestamp']);

                              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance.collection('splits').doc(splitId).get(),
                                builder: (context, splitSnapshot) {
                                  if (splitSnapshot.hasError) {
                                    return Text("Split Error: ${splitSnapshot.error}", style: GoogleFonts.poppins());
                                  }
                                  String description = 'Unknown';
                                  if (splitSnapshot.hasData && splitSnapshot.data!.exists) {
                                    var splitData = splitSnapshot.data!.data()!;
                                    description = splitData['description'] ?? 'No description';
                                  }

                                  return Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF234567),
                                        child: Text(senderName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                                      ),
                                      title: Text("$senderName sent a reminder",
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Split details of '$description'",
                                              style: const TextStyle(fontStyle: FontStyle.italic)),
                                          Text("Sent: $formattedDate",
                                              style: GoogleFonts.poppins(color: Colors.grey[600])),
                                        ],
                                      ),
                                      trailing: GestureDetector(
                                        onTap: () => goToExpenseHistoryDetail(splitId),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "View Details",
                                            style: GoogleFonts.poppins(
                                              color: Colors.blue,
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
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_showBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideInDown(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blueAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bannerTitle ?? "Notification",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _bannerBody ?? "",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _showBanner = false);
                            if (_bannerSplitId != null) {
                              goToExpenseHistoryDetail(_bannerSplitId!);
                            }
                          },
                          child: Text(
                            "View",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
}