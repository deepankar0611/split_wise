import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:split_wise/Home%20screen/notification.dart';
import 'package:split_wise/Home%20screen/spendanalyser.dart';
import 'package:split_wise/Profile/all%20expense%20history%20detals.dart';
import 'package:split_wise/Home%20screen/split%20details.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  Map<String, dynamic> userData = {
    "profileImageUrl": "",
    "amountToPay": "0",
    "amountToReceive": "0",
  };

  final List<String> categories = [
    "Grocery",
    "Medicine",
    "Food",
    "Rent",
    "Travel",
    "Shopping",
    "Entertainment",
    "Utilities",
    "Others",
  ];

  final Map<String, Map<String, dynamic>> categoryIcons = {
    "Grocery": {"icon": LucideIcons.shoppingCart, "color": Colors.teal},
    "Medicine": {"icon": LucideIcons.pill, "color": Colors.red},
    "Food": {"icon": LucideIcons.utensils, "color": Colors.orange},
    "Rent": {"icon": LucideIcons.home, "color": Colors.brown},
    "Travel": {"icon": LucideIcons.car, "color": Colors.blueAccent},
    "Shopping": {"icon": LucideIcons.gift, "color": Colors.pinkAccent},
    "Entertainment": {"icon": LucideIcons.film, "color": Colors.purple},
    "Utilities": {"icon": LucideIcons.lightbulb, "color": Colors.blueGrey},
    "Others": {"icon": LucideIcons.circleDollarSign, "color": Colors.grey},
  };

  final Map<String, Map<String, dynamic>> serviceIcons = {
    "Swiggy": {"icon": LucideIcons.fastForward, "color": Colors.orange},
    "Zepto": {"icon": LucideIcons.zap, "color": Colors.purple},
    "Instamart": {"icon": LucideIcons.shoppingBag, "color": Colors.deepPurple},
    "Blinkit": {"icon": LucideIcons.clock, "color": Colors.yellow},
    "Zomato": {"icon": LucideIcons.utensils, "color": Colors.red},
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (userId == 'defaultUserId') return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        if (mounted) {
          setState(() {
            userData = {
              "profileImageUrl": data.containsKey("profileImageUrl") ? data["profileImageUrl"] : "",
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

  Stream<Map<String, Map<String, dynamic>>> _streamTotalPaidByCategory() {
    return FirebaseFirestore.instance
        .collection('splits')
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      Map<String, Map<String, dynamic>> categoryData = {};
      for (var splitDoc in snapshot.docs) {
        Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
        String category = splitData['category'] ?? 'Others';
        Map<String, dynamic> paidBy = splitData['paidBy'] as Map<String, dynamic>? ?? {};
        double userPaidAmount = paidBy[userId]?.toDouble() ?? 0.0;
        Timestamp? createdAt = splitData['createdAt'] as Timestamp?;

        if (userPaidAmount > 0) {
          if (!categoryData.containsKey(category)) {
            categoryData[category] = {
              'totalPaid': 0.0,
              'lastInvolved': createdAt?.toDate(),
            };
          }
          categoryData[category]!['totalPaid'] = (categoryData[category]!['totalPaid'] as double) + userPaidAmount;
          if (createdAt != null &&
              (categoryData[category]!['lastInvolved'] == null ||
                  createdAt.toDate().isAfter(categoryData[category]!['lastInvolved'] as DateTime))) {
            categoryData[category]!['lastInvolved'] = createdAt.toDate();
          }
        }
      }
      return categoryData;
    });
  }

  Stream<bool> _isSplitSettledStream(String splitId) {
    return FirebaseFirestore.instance
        .collection('splits')
        .doc(splitId)
        .collection('settle')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? (snapshot.get('settled') as bool? ?? false) : false)
        .handleError((error, stackTrace) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF234567),
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: screenHeight * 0.3,
            backgroundColor: const Color(0xFF234567),
            centerTitle: true,
            title: Text(
              'Settle Up',
              style: GoogleFonts.lobster(
                 textStyle: TextStyle( // Removed redundant TextStyle constructor and added const
                  color: Colors.white,
                  fontSize: 24.0, // Adjust font size for stylish fonts
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black26,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final collapseProgress = (screenHeight * 0.3 - constraints.biggest.height) / (screenHeight * 0.3 - kToolbarHeight);
                final cardAnimationProgress = collapseProgress.clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.08), // Padding for FlexibleSpaceBar title (not used now)
                  background: Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.12),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.03),
                      child: Transform.translate(
                        offset: Offset(0, cardAnimationProgress * screenHeight * 0.1),
                        child: Transform.scale(
                          scale: 1.0 - cardAnimationProgress * 0.2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.015),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(screenWidth * 0.05),
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
                                Expanded(child: _buildReceiveCard()),
                                Expanded(child: _buildPayCard()),
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
                radius: screenWidth * 0.05,
                backgroundImage: userData["profileImageUrl"].isNotEmpty
                    ? NetworkImage(userData["profileImageUrl"])
                    : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
                backgroundColor: Colors.grey,
              ),
              onPressed: () {},
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.bell, color: Colors.white, size: screenWidth * 0.06),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseHistoryDetailedScreen(
              isReceiver: true,
              showFilter: '',
              splitId: '',
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.025),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 7, offset: const Offset(0, 3)),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.15), // Adjust as needed
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01, vertical: screenHeight * 0.005),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "Receive",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: screenWidth * 0.025),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.015),
                  child: Text(
                    "₹${amountToReceive.toInt()}",
                    style: TextStyle(fontSize: screenWidth * 0.07, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.015, bottom: screenHeight * 0.005),
                  child: Text(
                    "will get",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: screenWidth * 0.035),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayCard() {
    double amountToPay = double.tryParse(userData["amountToPay"]) ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseHistoryDetailedScreen(
              isPayer: false,
              showFilter: '',
              splitId: '',
              friendUid: '',
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.025),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.15), // Adjust as needed
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Pay",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.025,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.015),
                  child: Text(
                    "₹${amountToPay.toInt()}",
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.015,
                    bottom: screenHeight * 0.005,
                  ),
                  child: Text(
                    "will pay",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyCard() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      padding: EdgeInsets.only(top: screenWidth * 0.05),
      child: Column(
        children: [
          _buildHistoryCardBox(),
          SizedBox(height: screenWidth * 0.05),
          _buildExclusiveFeatureCard(),
          SizedBox(height: screenWidth * 0.05),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildHistoryCardBox() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('splits')
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
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

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recent Priority Bills",
                style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: screenHeight * 0.015),
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 7, offset: const Offset(0, 3)),
                  ],
                ),
                height: screenHeight * 0.18, // 18% of screen height
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var splitDoc = snapshot.data!.docs[index];
                    Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
                    Map<String, dynamic> paidBy = splitData['paidBy'] as Map<String, dynamic>? ?? {};
                    double userPaidAmount = paidBy[currentUserUid]?.toDouble() ?? 0.0;
                    double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
                    int participantCount = (splitData['participants'] as List<dynamic>?)?.length ?? 1;
                    double userShare = totalAmount / participantCount;
                    double netAmount = userShare - userPaidAmount;
                    String displayAmount = netAmount >= 0 ? "-₹${netAmount.toStringAsFixed(2)}" : "+₹${(-netAmount).toStringAsFixed(2)}";

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SplitDetailScreen(splitId: splitDoc.id),
                          ),
                        );
                      },
                      child: _buildHistoryItem(
                        title: splitData['description'] ?? 'Unknown Bill',
                        date: (splitData['createdAt'] as Timestamp?)?.toDate().toString() ?? DateTime.now().toString(),
                        amount: displayAmount,
                        color: Colors.blueAccent,
                        splitId: splitDoc.id,
                        settled: netAmount.abs() < 0.01,
                      ),
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

  Widget _buildExclusiveFeatureCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final List<String> card = [
      "assets/logo/spend.jpg",
      "assets/images/expense.png",
      "assets/images/expense.png",
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "EXCLUSIVE FEATURE",
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          SizedBox(
            height: screenHeight * 0.2, // 20% of screen height
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('splits')
                  .where('participants', arrayContains: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: card.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: index == 0
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpendAnalyzerScreen(
                                categoryData: <String, Map<String, dynamic>>{},
                                amountToPay: 0.0,
                                amountToReceive: 0.0,
                              ),
                            ),
                          );
                        }
                            : null,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                          width: screenWidth * 0.9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            image: DecorationImage(
                              image: AssetImage(card[index]),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                double totalAmountToPay = 0.0;
                double totalAmountToReceive = 0.0;
                Map<String, Map<String, dynamic>> categoryData = {};

                for (var splitDoc in snapshot.data!.docs) {
                  Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
                  Map<String, dynamic> paidBy = splitData['paidBy'] as Map<String, dynamic>? ?? {};
                  double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
                  int participantCount = (splitData['participants'] as List<dynamic>?)?.length ?? 1;
                  double userPaidAmount = paidBy[userId]?.toDouble() ?? 0.0;
                  double userShare = totalAmount / participantCount;
                  double netAmount = userShare - userPaidAmount;

                  if (netAmount > 0) {
                    totalAmountToPay += netAmount;
                  } else if (netAmount < 0) {
                    totalAmountToReceive += netAmount.abs();
                  }

                  String category = splitData['category'] ?? 'Others';
                  Timestamp? createdAt = splitData['createdAt'] as Timestamp?;
                  if (userPaidAmount > 0) {
                    if (!categoryData.containsKey(category)) {
                      categoryData[category] = {
                        'totalPaid': 0.0,
                        'lastInvolved': createdAt?.toDate(),
                      };
                    }
                    categoryData[category]!['totalPaid'] = (categoryData[category]!['totalPaid'] as double) + userPaidAmount;
                    if (createdAt != null &&
                        (categoryData[category]!['lastInvolved'] == null ||
                            createdAt.toDate().isAfter(categoryData[category]!['lastInvolved'] as DateTime))) {
                      categoryData[category]!['lastInvolved'] = createdAt.toDate();
                    }
                  }
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: card.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: index == 0
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpendAnalyzerScreen(
                              categoryData: categoryData,
                              amountToPay: totalAmountToPay,
                              amountToReceive: totalAmountToReceive,
                            ),
                          ),
                        );
                      }
                          : null,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                        width: screenWidth * 0.9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          image: DecorationImage(
                            image: AssetImage(card[index]),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required String amount,
    required Color color,
    required String splitId,
    bool settled = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    DateTime createdAtDate = DateTime.parse(date);
    String timeAgo = _formatTimeAgo(createdAtDate);

    return StreamBuilder<bool>(
      stream: _isSplitSettledStream(splitId),
      builder: (context, settleSnapshot) {
        if (settleSnapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: screenWidth * 0.4,
              margin: EdgeInsets.only(right: screenWidth * 0.04),
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
            ),
          );
        }
        if (settleSnapshot.hasError) {
          return _buildUnsettledHistoryItem(title, date, amount, color, settled);
        }

        bool isSettled = settleSnapshot.data ?? false;

        return Container(
          width: screenWidth * 0.4,
          margin: EdgeInsets.only(right: screenWidth * 0.04),
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isSettled)
                    Icon(
                      LucideIcons.zap,
                      color: Colors.amber,
                      size: screenWidth * 0.04,
                    ),
                ],
              ),
              SizedBox(height: screenWidth * 0.005), // Reduced from 0.01
              Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: screenWidth * 0.005), // Reduced from 0.01
              Text(
                isSettled ? "Settled" : "Unsettled",
                style: TextStyle(
                  color: isSettled ? Colors.green[600] : Colors.grey[600],
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (!isSettled)
                Padding(
                  padding: EdgeInsets.only(top: screenWidth * 0.01), // Reduced from 0.015
                  child: Text(
                    amount,
                    style: TextStyle(
                      color: amount.startsWith('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.035,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnsettledHistoryItem(String title, String date, String amount, Color color, bool settled) {
    final screenWidth = MediaQuery.of(context).size.width;
    DateTime createdAtDate = DateTime.parse(date);
    String timeAgo = _formatTimeAgo(createdAtDate);

    return Container(
      width: screenWidth * 0.35,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.035),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (settled) Icon(LucideIcons.zap, color: Colors.amber, size: screenWidth * 0.04),
            ],
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            settled ? "Settled" : timeAgo,
            style: TextStyle(
              color: settled ? Colors.green[600] : Colors.grey[600],
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (!settled)
            Padding(
              padding: EdgeInsets.only(top: screenWidth * 0.015),
              child: Text(
                amount,
                style: TextStyle(
                  color: amount.startsWith('+') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.035,
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
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<Map<String, Map<String, dynamic>>>(
      stream: _streamTotalPaidByCategory(),
      builder: (context, AsyncSnapshot<Map<String, Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categoryData = snapshot.hasData ? snapshot.data! : {};

        List<MapEntry<String, Map<String, dynamic>>> sortedCategories = categories
            .map<MapEntry<String, Map<String, dynamic>>>((category) {
          return MapEntry(
            category,
            categoryData[category] ?? {'totalPaid': 0.0, 'lastInvolved': null},
          );
        })
            .toList()
          ..sort((a, b) {
            DateTime? timeA = a.value['lastInvolved'] as DateTime?;
            DateTime? timeB = b.value['lastInvolved'] as DateTime?;
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeB.compareTo(timeA);
          });

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Overview",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Column(
                children: sortedCategories.map((entry) {
                  String category = entry.key;
                  double totalPaid = entry.value['totalPaid']?.toDouble() ?? 0.0;
                  DateTime? lastInvolved = entry.value['lastInvolved'] as DateTime?;
                  String subtitle = lastInvolved != null ? _formatTimeAgo(lastInvolved) : "Never";
                  return _buildTransactionItem(
                    categoryIcons[category]!['icon'],
                    category,
                    subtitle,
                    "₹${totalPaid.toStringAsFixed(2)}",
                    categoryIcons[category]!['color'],
                    category,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    Duration difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }

  Widget _buildTransactionItem(IconData icon, String title, String subtitle, String amount, Color color, String category) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseHistoryDetailedScreen(
              category: category,
              showFilter: '',
              splitId: '',
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025, horizontal: screenWidth * 0.03),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: color.withOpacity(0.4),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Icon(icon, color: color, size: screenWidth * 0.07),
            ),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.035),
            ),
            trailing: Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
                color: Colors.green,
              ),
            ),
          ),
        ),
      ),
    );
  }
}