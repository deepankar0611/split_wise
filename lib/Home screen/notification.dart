import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  Map<String, String> userNames = {};

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupNotificationListeners();
    _preloadUserNames();
  }

  Future<void> _preloadUserNames() async {
    var userDocs = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      for (var doc in userDocs.docs) {
        userNames[doc.id] = doc.data()['name'] ?? 'Unknown';
      }
    });
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
          String fromUid = data['fromUid'];
          _fetchUserName(fromUid).then((name) {
            _showNotification(
              "Friend Request",
              "$name sent a friend request",
              change.doc.id,
            );
          });
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
          String sentBy = data['sentBy'];
          FirebaseFirestore.instance.collection('splits').doc(splitId).get().then((splitDoc) {
            String description = splitDoc.data()?['description'] ?? 'No description';
            _fetchUserName(sentBy).then((name) {
              _showNotification(
                "$name sent a reminder",
                "Split details of '$description'",
                splitId,
              );
            });
          });
        }
      }
    });
  }

  Future<String> _fetchUserName(String uid) async {
    if (userNames.containsKey(uid)) {
      return userNames[uid]!;
    }
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    String name = userDoc.data()?['name'] ?? 'Unknown';
    setState(() {
      userNames[uid] = name;
    });
    return name;
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

  void _showSnackBar(String message, {VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        action: onUndo != null
            ? SnackBarAction(
          label: 'Undo',
          textColor: Colors.yellow,
          onPressed: onUndo,
        )
            : null,
      ),
    );
  }

  Future<void> _deleteNotification(String type, String id, String? splitId) async {
    try {
      if (type == 'friend_request') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('friend_requests')
            .doc(id)
            .delete();
      } else if (type == 'split_reminder' && splitId != null) {
        await FirebaseFirestore.instance
            .collection('splits')
            .doc(splitId)
            .collection('reminders')
            .doc(id)
            .update({
          'dismissedBy': FieldValue.arrayUnion([currentUserUid]),
        });
      }
      setState(() {});
    } catch (e) {
      _showSnackBar("Error deleting notification: $e");
    }
  }

  Future<void> _undoDelete(String type, String id, String? splitId, Map<String, dynamic> data) async {
    try {
      if (type == 'friend_request') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('friend_requests')
            .doc(id)
            .set(data);
      } else if (type == 'split_reminder' && splitId != null) {
        await FirebaseFirestore.instance
            .collection('splits')
            .doc(splitId)
            .collection('reminders')
            .doc(id)
            .update({
          'dismissedBy': FieldValue.arrayRemove([currentUserUid]),
        });
      }
      setState(() {});
    } catch (e) {
      _showSnackBar("Error undoing deletion: $e");
    }
  }

  Future<void> _deleteAllNotifications(List<Map<String, dynamic>> allNotifications) async {
    try {
      List<Map<String, dynamic>> deletedNotifications = [];

      for (var notification in allNotifications) {
        if (notification['type'] == 'friend_request') {
          deletedNotifications.add({
            'type': notification['type'],
            'id': notification['id'],
            'splitId': null,
            'data': notification['data'],
          });
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserUid)
              .collection('friend_requests')
              .doc(notification['id'])
              .delete();
        } else if (notification['type'] == 'split_reminder') {
          String splitId = notification['splitId'];
          List<dynamic> dismissedBy = notification['data']['dismissedBy'] ?? [];
          if (!dismissedBy.contains(currentUserUid)) {
            deletedNotifications.add({
              'type': notification['type'],
              'id': notification['id'],
              'splitId': splitId,
              'data': notification['data'],
            });
            await FirebaseFirestore.instance
                .collection('splits')
                .doc(splitId)
                .collection('reminders')
                .doc(notification['id'])
                .update({
              'dismissedBy': FieldValue.arrayUnion([currentUserUid]),
            });
          }
        }
      }

      _showSnackBar(
        "All notifications deleted",
        onUndo: () async {
          for (var deleted in deletedNotifications) {
            await _undoDelete(deleted['type'], deleted['id'], deleted['splitId'], deleted['data']);
          }
        },
      );
      setState(() {});
    } catch (e) {
      _showSnackBar("Error deleting all notifications: $e");
    }
  }

  Future<void> _confirmDeleteAllNotifications(List<Map<String, dynamic>> allNotifications) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete All Notifications", style: GoogleFonts.poppins()),
          content: Text(
            "Are you sure you want to delete all notifications? This action will remove all friend requests and dismiss all reminders.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteAllNotifications(allNotifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF234567),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Delete All",
            onPressed: () async {
              final friendSnapshot = await getFriendRequests().first;
              final reminderSnapshot = await getSplitReminders().first;

              List<Map<String, dynamic>> allNotifications = [];

              if (friendSnapshot.docs.isNotEmpty) {
                allNotifications.addAll(friendSnapshot.docs.map((doc) {
                  var data = doc.data();
                  return {
                    'type': 'friend_request',
                    'data': data,
                    'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    'id': doc.id,
                  };
                }));
              }

              if (reminderSnapshot.docs.isNotEmpty) {
                allNotifications.addAll(reminderSnapshot.docs.map((doc) {
                  var data = doc.data();
                  String splitId = data['splitId'] ?? doc.reference.parent.parent!.id;
                  return {
                    'type': 'split_reminder',
                    'data': data,
                    'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    'id': doc.id,
                    'splitId': splitId,
                  };
                }));
              }

              if (allNotifications.isNotEmpty) {
                _confirmDeleteAllNotifications(allNotifications);
              } else {
                _showSnackBar("No notifications to delete");
              }
            },
          ),
        ],
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
                          return FutureBuilder<String>(
                            future: _fetchUserName(senderUid),
                            builder: (context, nameSnapshot) {
                              if (!nameSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              String senderName = nameSnapshot.data!;
                              String formattedDate = DateFormat('dd MMM, hh:mm a').format(notification['timestamp']);
                              return Dismissible(
                                key: Key(notification['id']),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  var deletedData = notification['data'];
                                  _deleteNotification(notification['type'], notification['id'], null);
                                  _showSnackBar(
                                    "Friend request deleted",
                                    onUndo: () => _undoDelete(
                                      notification['type'],
                                      notification['id'],
                                      null,
                                      deletedData,
                                    ),
                                  );
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF234567),
                                      child: Text(senderName[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white)),
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

                          return FutureBuilder<String>(
                            future: _fetchUserName(senderUid),
                            builder: (context, nameSnapshot) {
                              if (!nameSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              String senderName = nameSnapshot.data!;
                              String formattedDate = DateFormat('dd MMM, hh:mm a').format(notification['timestamp']);

                              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance.collection('splits').doc(splitId).get(),
                                builder: (context, splitSnapshot) {
                                  if (splitSnapshot.hasError) {
                                    return Text("Split Error: ${splitSnapshot.error}",
                                        style: GoogleFonts.poppins());
                                  }
                                  String description = 'Unknown';
                                  if (splitSnapshot.hasData && splitSnapshot.data!.exists) {
                                    var splitData = splitSnapshot.data!.data()!;
                                    description = splitData['description'] ?? 'No description';
                                  }

                                  return Dismissible(
                                    key: Key(reminderId),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) {
                                      var deletedData = notification['data'];
                                      _deleteNotification(notification['type'], reminderId, splitId);
                                      _showSnackBar(
                                        "Reminder dismissed",
                                        onUndo: () => _undoDelete(
                                          notification['type'],
                                          reminderId,
                                          splitId,
                                          deletedData,
                                        ),
                                      );
                                    },
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(0xFF234567),
                                          child: Text(senderName[0].toUpperCase(),
                                              style: const TextStyle(color: Colors.white)),
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
        ],
      ),
    );
  }
}