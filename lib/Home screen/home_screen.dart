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

  Map<String, Map<String, dynamic>> categoryData = {};
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchUserData();
    await _fetchCategoryData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
              "profileImageUrl": data["profileImageUrl"] as String? ?? "",
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

  Future<void> _fetchCategoryData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('splits')
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Initialize all categories with default values
      Map<String, Map<String, dynamic>> tempCategoryData = {
        for (var category in categories)
          category: {'averageAmount': 0.0, 'lastInvolved': null}
      };

      // Temporary maps to aggregate data per category
      Map<String, double> totalAmountPerCategory = {};
      Map<String, int> splitCountPerCategory = {};

      for (var splitDoc in snapshot.docs) {
        Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
        String category = splitData['category'] ?? 'Others';
        double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
        int participantCount = (splitData['participants'] as List<dynamic>?)?.length ?? 1;
        Timestamp? createdAt = splitData['createdAt'] as Timestamp?;

        // Aggregate total amount and count of splits for averaging
        totalAmountPerCategory[category] = (totalAmountPerCategory[category] ?? 0.0) + totalAmount;
        splitCountPerCategory[category] = (splitCountPerCategory[category] ?? 0) + 1;

        // Update lastInvolved if this split is more recent
        if (createdAt != null &&
            (tempCategoryData[category]!['lastInvolved'] == null ||
                createdAt.toDate().isAfter(tempCategoryData[category]!['lastInvolved'] as DateTime))) {
          tempCategoryData[category]!['lastInvolved'] = createdAt.toDate();
        }
      }

      // Calculate average amount per participant for each category
      totalAmountPerCategory.forEach((category, totalAmount) {
        int splitCount = splitCountPerCategory[category] ?? 1;
        double avgTotalAmount = totalAmount / splitCount; // Average total amount per split
        int avgParticipantCount = snapshot.docs
            .where((doc) => (doc.data() as Map<String, dynamic>)['category'] == category)
            .map((doc) => ((doc.data() as Map<String, dynamic>)['participants'] as List<dynamic>?)?.length ?? 1)
            .reduce((a, b) => a + b) ~/ splitCountPerCategory[category]!; // Average participants per split
        tempCategoryData[category]!['averageAmount'] = avgTotalAmount / avgParticipantCount;
      });

      if (mounted) {
        setState(() {
          categoryData = tempCategoryData;
        });
      }
    } catch (e) {
      print("Error fetching category data: $e");
      if (mounted) {
        setState(() {
          categoryData = {
            for (var category in categories)
              category: {'averageAmount': 0.0, 'lastInvolved': null}
          };
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchUserData();
    await _fetchCategoryData();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: screenHeight * 0.3,
              backgroundColor: const Color(0xFF234567),
              centerTitle: true,
              title: Text(
                'Split Up',
                style: GoogleFonts.lobster(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
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
                    background: Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.03),
                        child: Transform.translate(
                          offset: Offset(0, cardAnimationProgress * screenHeight * 0.1),
                          child: Transform.scale(
                            scale: 1.0 - cardAnimationProgress * 0.2,
                            child: _isLoading
                                ? _buildShimmerCard(screenWidth, screenHeight)
                                : Container(
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
                  backgroundImage: userData["profileImageUrl"] != null && (userData["profileImageUrl"] as String).isNotEmpty
                      ? NetworkImage(userData["profileImageUrl"] as String)
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
                _isLoading ? _buildShimmerBodyCard(screenWidth, screenHeight) : _buildBodyCard(),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Container(
                height: screenHeight * 0.1,
                color: Colors.grey[300],
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Container(
                height: screenHeight * 0.1,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBodyCard(double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      padding: EdgeInsets.only(top: screenWidth * 0.05),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.02,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                SizedBox(
                  height: screenHeight * 0.18,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: screenWidth * 0.4,
                          margin: EdgeInsets.only(right: screenWidth * 0.04),
                          color: Colors.grey[300],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth * 0.05),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: screenWidth * 0.3,
                    height: screenHeight * 0.02,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                SizedBox(
                  height: screenHeight * 0.2,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: screenWidth * 0.9,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth * 0.05),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: screenWidth * 0.3,
                    height: screenHeight * 0.02,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Column(
                  children: List.generate(
                    3,
                        (index) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                        height: screenHeight * 0.08,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveCard() {
    double amountToReceive = double.tryParse(userData["amountToReceive"] as String? ?? "0") ?? 0;
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
              sendFilter: '',
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 7, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenHeight * 0.002),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "Receive",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.015, top: screenHeight * 0.002),
              child: Text(
                "₹${amountToReceive.toInt()}",
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.015),
              child: Text(
                "will get",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.025,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayCard() {
    double amountToPay = double.tryParse(userData["amountToPay"] as String? ?? "0") ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseHistoryDetailedScreen(
              isPayer: true,
              showFilter: '',
              splitId: '',
              sendFilter: '',
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenHeight * 0.002),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "Pay",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.015, top: screenHeight * 0.001),
              child: Text(
                "₹${amountToPay.toInt()}",
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.015),
              child: Text(
                "will pay",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.025,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
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
                height: screenHeight * 0.18,
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
      "assets/logo/reminder.jpg",
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
            height: screenHeight * 0.2,
            child: ListView.builder(
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
                          amountToPay: double.tryParse(userData["amountToPay"] as String? ?? "0") ?? 0.0,
                          amountToReceive: double.tryParse(userData["amountToReceive"] as String? ?? "0") ?? 0.0,
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
          padding: EdgeInsets.all(screenWidth * 0.02),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.035),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isSettled) Icon(LucideIcons.zap, color: Colors.amber, size: screenWidth * 0.04),
                ],
              ),
              SizedBox(height: screenWidth * 0.005),
              Text(
                timeAgo,
                style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.03, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: screenWidth * 0.005),
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
                  padding: EdgeInsets.only(top: screenWidth * 0.01),
                  child: Text(
                    amount,
                    style: TextStyle(
                      color: amount.startsWith('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.033,
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

    // Use categoryData directly, which now includes all categories with average amounts
    List<MapEntry<String, Map<String, dynamic>>> sortedCategories = categoryData.entries.toList()
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
            style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Column(
            children: sortedCategories.map((entry) {
              String category = entry.key;
              double averageAmount = entry.value['averageAmount']?.toDouble() ?? 0.0;
              DateTime? lastInvolved = entry.value['lastInvolved'] as DateTime?;
              String subtitle = lastInvolved != null ? _formatTimeAgo(lastInvolved) : "Never";
              return _buildTransactionItem(
                categoryIcons[category]!['icon'] as IconData,
                category,
                subtitle,
                "₹${averageAmount.toStringAsFixed(2)}",
                categoryIcons[category]!['color'] as Color,
                category,
              );
            }).toList(),
          ),
        ],
      ),
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
              sendFilter: '',
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04, color: Colors.green),
            ),
          ),
        ),
      ),
    );
  }
}