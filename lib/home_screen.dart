import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:split_wise/notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  List<Map<String, dynamic>> historyList = [];


  Map<String, dynamic> userData = {
    "profileImageUrl": "",
    "amountToPay": "0",
    "amountToReceive": "0",
  };

  @override
  void initState() {
    super.initState();
    fetchUserHistory();
    _fetchUserData();
  }

  Future<List<Map<String, dynamic>>> fetchUserHistory() async {
    try {
      String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserUid == null) {
        print("⚠ User is not logged in");
        return [];
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('splits').get();
      print("📌 Retrieved ${querySnapshot.docs.length} documents from Firestore");

      List<Map<String, dynamic>> historyList = [];

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        List<dynamic> participants = doc['participants'] ?? [];
        print("📌 Document ID: ${doc.id}, Participants: $participants");

        if (participants.contains(currentUserUid)) {
          print("✅ User is a participant in: ${doc.id}");

          historyList.add({
            'description': doc['description'] ?? 'Unknown Bill',
            'createdAt': (doc['createdAt'] as Timestamp).toDate().toString(),
            'totalAmount': "\$${doc['totalAmount']?.toString() ?? '0.00'}",
          });
        }
      }

      print("✅ Final Fetched History List: $historyList");
      return historyList;
    } catch (e) {
      print("❌ Error fetching history: $e");
      return [];
    }
  }




  Future<void> _fetchUserData() async {
    if (userId == 'defaultUserId') return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        if (mounted) {
          setState(() {
            userData = {
              "profileImageUrl": data.containsKey("profileImageUrl")
                  ? data["profileImageUrl"]
                  : "",
              "amountToPay": data["amountToPay"]?.toString() ?? "0",
              "amountToReceive": data["amountToReceive"]?.toString() ?? "0",
            };
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> fetchUserSplits() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("⚠ User not logged in");
        return;
      }

      // Fetch all splits where the current user is a participant
      QuerySnapshot splitSnapshot = await firestore
          .collection('splits')
          .where('participants', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> splitsData = [];

      for (var splitDoc in splitSnapshot.docs) {
        String splitId = splitDoc.id;
        Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;

        // Fetch transactions for this split
        QuerySnapshot transactionSnapshot = await firestore
            .collection('splits')
            .doc(splitId)
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .get();

        List<Map<String, dynamic>> transactions = transactionSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        splitData['transactions'] = transactions;
        splitsData.add(splitData);
      }

      print("✅ Data fetched successfully");
      print(splitsData); // Print fetched data for debugging

    } catch (e) {
      print("❌ Error fetching data: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF234567),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 220.0,
            backgroundColor: const Color(0xFF234567),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final collapseProgress = (220.0 - constraints.biggest.height) / (220.0 - kToolbarHeight);
                final cardAnimationProgress = collapseProgress.clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                  title: null,
                  background: Padding(
                    padding: const EdgeInsets.only(top: 90.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Transform.translate(
                        offset: Offset(0, cardAnimationProgress * 70),
                        child: Transform.scale(
                          scale: 1.0 - cardAnimationProgress * 0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildReceiveCard(),
                                _buildPayCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            leading: IconButton(
              icon: CircleAvatar(
                radius: 20,
                backgroundImage: userData["profileImageUrl"].isNotEmpty
                    ? NetworkImage(userData["profileImageUrl"])
                    : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                backgroundColor: Colors.grey,
              ),
              onPressed: () {},
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Notificationn()),
                  );
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildBodyCard(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveCard() {
    double amountToReceive = double.tryParse(userData["amountToReceive"]) ?? 0;
    return Container(
      width: 170,
      height: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Receive",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Text(
              "₹${amountToReceive.toInt()}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 6.0, bottom: 4.0),
            child: Text(
              "will get",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return const Center(child: Text("No data available"));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        double amountToPay = double.tryParse(data["amountToPay"]?.toString() ?? "0") ?? 0;

        return Container(
          width: 170,
          height: 120,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Pay",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Text(
                  "₹${amountToPay.toInt()}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6.0, bottom: 4.0),
                child: Text(
                  "will pay",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // The rest of your code (e.g., _buildBodyCard, _buildHistoryCardBox, etc.) remains unchanged
  // Add them here as they were in your original code...

  Widget _buildBodyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          _buildHistoryCardBox(),
          const SizedBox(height: 20),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildHistoryCardBox() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('splits').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No recent priority bills."));
        }

        String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserUid == null) {
          return const Center(child: Text("User not logged in"));
        }

        // Filter splits where the current user is a participant
        List<Map<String, dynamic>> historyList = snapshot.data!.docs
            .where((doc) => (doc['participants'] as List<dynamic>?)?.contains(currentUserUid) ?? false)
            .map((doc) => {
          'description': doc['description'] ?? 'Unknown Bill',
          'createdAt': (doc['createdAt'] as Timestamp).toDate().toString(),
          'totalAmount': "₹${doc['totalAmount']?.toString() ?? '0.00'}",
        })
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recent Priority Bills",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    var history = historyList[index];
                    return _buildHistoryItem(
                      title: history['description'],
                      date: history['createdAt'],
                      amount: history['totalAmount'],
                      color: Colors.blueAccent,
                      settled: index % 2 == 0,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildHistoryItem({
    required String title,
    required String date,
    required String amount,
    required Color color,
    bool settled = false,
  }) {
    // Convert the stored date string into DateTime object
    DateTime createdAtDate = DateTime.parse(date);
    Duration difference = DateTime.now().difference(createdAtDate);

    // Determine the time display (e.g., "2 days ago", "1 week ago", "Just now")
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      timeAgo = "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else {
      timeAgo = "Just now";
    }

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (settled)
                const Icon(LucideIcons.zap, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            settled ? "Settled" : timeAgo,  // Updated this line
            style: TextStyle(
                color: settled ? Colors.green[600] : Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (!settled)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                amount,
                style: TextStyle(
                  color: amount.startsWith('+') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildTransactionList() {
    final List<Map<String, dynamic>> transactions = [
      {"icon": LucideIcons.car, "title": "Uber", "subtitle": "He paid \₹39.60", "amount": "-\₹19.80", "color": Colors.orange},
      {"icon": LucideIcons.shoppingCart, "title": "Groceries", "subtitle": "You paid \₹124.16", "amount": "+\₹62.08", "color": Colors.teal},
      {"icon": LucideIcons.mapPin, "title": "Adventures", "subtitle": "Shared group", "amount": "-\₹15.99", "color": Colors.blueAccent},
      {"icon": LucideIcons.film, "title": "Cinema", "subtitle": "He paid \₹40.00", "amount": "-\₹20.00", "color": Colors.purple},
      {"icon": LucideIcons.gift, "title": "Present for Andy", "subtitle": "He paid \₹64.30", "amount": "-\₹64.30", "color": Colors.pinkAccent},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Column(
            children: transactions.map((transaction) => _buildTransactionItem(
              transaction['icon'],
              transaction['title'],
              transaction['subtitle'],
              transaction['amount'],
              transaction['color'],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(IconData icon, String title, String subtitle, String amount, Color color) {
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          trailing: Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: amount.startsWith('+') ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}