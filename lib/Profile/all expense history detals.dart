import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:split_wise/Home%20screen/split%20details.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExpenseHistoryDetailedScreen extends StatefulWidget {
  final String? friendUid;
  final String? category;
  final bool? isPayer;
  final bool? isReceiver;

  const ExpenseHistoryDetailedScreen({
    super.key,
    this.friendUid,
    this.category,
    this.isPayer,
    this.isReceiver,
    required String showFilter,
    required String splitId,
  });

  @override
  State<ExpenseHistoryDetailedScreen> createState() => _ExpenseHistoryDetailedScreenState();
}

class _ExpenseHistoryDetailedScreenState extends State<ExpenseHistoryDetailedScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  String searchQuery = "";
  bool showSettled = true;
  String? friendName;
  String? friendProfileImageUrl;
  String? friendSinceDate;
  int totalSplitsTogether = 0;
  double avgAmountTogether = 0.0;

  @override
  void initState() {
    super.initState();
    print(
        "Initializing with friendUid: ${widget.friendUid}, category: ${widget.category}, isPayer: ${widget.isPayer}, isReceiver: ${widget.isReceiver}");
    if (widget.friendUid != null) {
      _fetchFriendDetails();
      _fetchFriendSinceDate();
      _fetchFriendshipStats();
    }
  }

  Future<void> _fetchFriendDetails() async {
    try {
      DocumentSnapshot friendDoc =
      await FirebaseFirestore.instance.collection('users').doc(widget.friendUid!).get();
      if (friendDoc.exists) {
        var data = friendDoc.data() as Map<String, dynamic>?;
        setState(() {
          friendName = data?['name'] ?? "Friend";
          friendProfileImageUrl = data?['profileImageUrl'] ?? "";
        });
      }
    } catch (e) {
      print("Error fetching friend details: $e");
      setState(() => friendName = "Friend");
    }
  }

  Future<void> _fetchFriendSinceDate() async {
    try {
      DocumentSnapshot friendShipDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(widget.friendUid!)
          .get();
      if (friendShipDoc.exists && friendShipDoc['friendSince'] != null) {
        DateTime date = (friendShipDoc['friendSince'] as Timestamp).toDate();
        setState(() {
          friendSinceDate = "${date.day}-${date.month}-${date.year}";
        });
      } else {
        setState(() {
          friendSinceDate = "Unknown";
        });
      }
    } catch (e) {
      print("Error fetching friend since date: $e");
      setState(() {
        friendSinceDate = "Unknown";
      });
    }
  }

  Future<void> _fetchFriendshipStats() async {
    try {
      QuerySnapshot splitsSnapshot = await FirebaseFirestore.instance
          .collection('splits')
          .where('participants', arrayContainsAny: [userId, widget.friendUid])
          .get();
      int count = 0;
      double totalAmount = 0.0;

      for (var doc in splitsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> participants = data['participants'] ?? [];
        if (participants.contains(userId) && participants.contains(widget.friendUid)) {
          count++;
          totalAmount += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      setState(() {
        totalSplitsTogether = count;
        avgAmountTogether = count > 0 ? totalAmount / count : 0.0;
      });
    } catch (e) {
      print("Error fetching friendship stats: $e");
    }
  }

  Future<void> _removeMyParticipation(String splitId) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Removal",
              style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width * 0.045, fontWeight: FontWeight.bold)),
          content: Text(
              "Are you sure you want to remove your participation from this split? This won’t affect other participants.",
              style: GoogleFonts.poppins(fontSize: MediaQuery.of(context).size.width * 0.04)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Remove", style: GoogleFonts.poppins(color: Colors.red))),
          ],
        ),
      );

      if (confirm != true) return;

      DocumentSnapshot splitDoc =
      await FirebaseFirestore.instance.collection('splits').doc(splitId).get();
      if (!splitDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Split not found.", style: GoogleFonts.poppins())));
        return;
      }

      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(splitData['participants'] ?? []);
      Map<String, dynamic> paidBy = Map<String, dynamic>.from(splitData['paidBy'] ?? {});

      if (!participants.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You are not part of this split.", style: GoogleFonts.poppins())));
        return;
      }

      participants.remove(userId);
      paidBy.remove(userId);

      await FirebaseFirestore.instance.collection('splits').doc(splitId).update({
        'participants': participants,
        'paidBy': paidBy.isEmpty ? FieldValue.delete() : paidBy,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Your participation has been removed.", style: GoogleFonts.poppins())));
    } catch (e) {
      print("Error removing participation: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to remove participation: $e", style: GoogleFonts.poppins())));
    }
  }

  Future<void> _deleteEntireSplit(String splitId) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Delete",
              style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width * 0.045, fontWeight: FontWeight.bold)),
          content: Text(
              "Are you sure you want to delete this split entirely? This will remove it for all participants.",
              style: GoogleFonts.poppins(fontSize: MediaQuery.of(context).size.width * 0.04)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red))),
          ],
        ),
      );

      if (confirm != true) return;

      DocumentSnapshot splitDoc =
      await FirebaseFirestore.instance.collection('splits').doc(splitId).get();
      if (!splitDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Split not found.", style: GoogleFonts.poppins())));
        return;
      }

      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
      String? creatorId = splitData['createdBy'] as String?;

      if (creatorId != userId) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Only the creator can delete this split entirely.",
                style: GoogleFonts.poppins())));
        return;
      }

      await FirebaseFirestore.instance.collection('splits').doc(splitId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
          Text("Split has been deleted for all participants.", style: GoogleFonts.poppins())));
      setState(() {});
    } catch (e) {
      print("Error deleting split: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to delete split: $e", style: GoogleFonts.poppins())));
    }
  }

  Future<bool> _isUserPayerInTransactions(String splitId) async {
    try {
      QuerySnapshot transactionSnapshot = await FirebaseFirestore.instance
          .collection('splits')
          .doc(splitId)
          .collection('transactions')
          .where('from', isEqualTo: userId)
          .limit(1)
          .get();
      return transactionSnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking payer transactions for split $splitId: $e");
      return false;
    }
  }

  Future<bool> _isUserReceiverInTransactions(String splitId) async {
    try {
      QuerySnapshot transactionSnapshot = await FirebaseFirestore.instance
          .collection('splits')
          .doc(splitId)
          .collection('transactions')
          .where('to', isEqualTo: userId)
          .limit(1)
          .get();
      return transactionSnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking receiver transactions for split $splitId: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.isPayer == true
              ? "Splits You Paid"
              : widget.isReceiver == true
              ? "Splits You Received"
              : widget.category != null
              ? "Splits in ${widget.category}"
              : widget.friendUid != null
              ? "Splits with ${friendName ?? 'Friend'}"
              : "Expense History",
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: screenWidth * 0.045),
        ),
        backgroundColor: const Color(0xFF234567),
        elevation: 4,
        centerTitle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05))),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.06),
            onPressed: () => Navigator.pop(context)),
        actions: widget.friendUid != null
            ? [
          IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: screenWidth * 0.06),
              onPressed: () => _showSearchBar(context)),
          IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white, size: screenWidth * 0.06),
              onPressed: () => _showFilterDialog(context)),
        ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.friendUid != null)
                  Stack(
                    children: [
                      _buildFriendDetailCard(screenWidth, screenHeight),
                    ],
                  ),
                SizedBox(height: screenHeight * 0.02),
                Stack(
                  children: [
                    Container(
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
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: _buildSplitsList(screenWidth, screenHeight),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendDetailCard(double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.05), // Increased padding for breathing room
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15), // Softer shadow
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: screenWidth * 0.09, // Slightly larger avatar
                backgroundColor: Colors.grey.shade200,
                foregroundImage: friendProfileImageUrl != null && friendProfileImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(friendProfileImageUrl!)
                    : null,
                child: friendProfileImageUrl == null || friendProfileImageUrl!.isEmpty
                    ? Icon(Icons.person, size: screenWidth * 0.09, color: Colors.grey.shade600)
                    : null,
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendName ?? "Friend",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.055, // Slightly larger for emphasis
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (friendSinceDate != null)
                      Text(
                        "Friends Since: $friendSinceDate",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w400, // Lighter weight for secondary info
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025), // Increased spacing
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, // Light background for stats section
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  screenWidth,
                  icon: Icons.group,
                  label: "Total Splits",
                  value: "$totalSplitsTogether",
                ),
                _buildStatColumn(
                  screenWidth,
                  icon: Icons.currency_rupee,
                  label: "Avg. Amount",
                  value: "₹${avgAmountTogether.toStringAsFixed(2)}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(double screenWidth, {required IconData icon, required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: screenWidth * 0.045,
              color: Colors.grey.shade700,
            ),
            SizedBox(width: screenWidth * 0.015),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.005),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitsList(double screenWidth, double screenHeight) {
    return SizedBox(
      height: screenHeight * 0.6, // Adjust height as needed
      child: StreamBuilder<QuerySnapshot>(
        stream: _buildSplitsStream(),
        builder: (context, snapshot) {
          print(
              "StreamBuilder state: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, error=${snapshot.error}");
          if (snapshot.connectionState == ConnectionState.waiting)
            return _buildShimmerGrid(screenWidth, screenHeight);
          if (snapshot.hasError) {
            print("Stream error: ${snapshot.error}");
            return Center(
                child: Text("Error: ${snapshot.error}",
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: screenWidth * 0.04)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print(
                "No splits found for userId=$userId, friendUid=${widget.friendUid}, category=${widget.category}, isPayer=${widget.isPayer}, isReceiver=${widget.isReceiver}");
            return Center(
              child: Text(
                widget.isPayer == true
                    ? "No splits where you paid yet."
                    : widget.isReceiver == true
                    ? "No splits where you received yet."
                    : widget.category != null
                    ? "No splits in ${widget.category} yet."
                    : widget.friendUid != null
                    ? "No splits with this friend yet."
                    : "No expense history yet.",
                style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, color: Colors.grey[600]!),
              ),
            );
          }

          var splits = snapshot.data!.docs;
          print("Total splits before filtering: ${splits.length}");

          return FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _filterSplits(splits),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting)
                return _buildShimmerGrid(screenWidth, screenHeight);
              if (futureSnapshot.hasError)
                return Center(
                    child: Text("Error: ${futureSnapshot.error}",
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: screenWidth * 0.04)));
              if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    widget.isPayer == true
                        ? "No splits where you paid found."
                        : widget.isReceiver == true
                        ? "No splits where you received found."
                        : widget.category != null
                        ? "No matching splits in ${widget.category} found."
                        : widget.friendUid != null
                        ? "No matching splits with this friend found."
                        : "No matching splits found.",
                    style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, color: Colors.grey[600]!),
                  ),
                );
              }

              var filteredSplits = futureSnapshot.data!;
              print("Filtered splits count: ${filteredSplits.length}");

              return ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: filteredSplits.length,
                itemBuilder: (context, index) {
                  var splitDoc = filteredSplits[index];
                  String splitId = splitDoc.id;
                  Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
                  Map<String, dynamic> paidBy = splitData['paidBy'] as Map<String, dynamic>? ?? {};
                  double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
                  int participantCount = (splitData['participants'] as List<dynamic>?)?.length ?? 1;
                  double userPaidAmount = (paidBy[userId] as num?)?.toDouble() ?? 0.0;

                  double sharePerPerson = totalAmount / participantCount;
                  double yourNet = sharePerPerson - userPaidAmount;
                  double netAmount = yourNet;
                  String displayAmount = netAmount >= 0
                      ? "-₹${netAmount.toStringAsFixed(2)}"
                      : "+₹${(-netAmount).toStringAsFixed(2)}";
                  bool isSettledFinancially = netAmount.abs() < 0.01;
                  String? creatorId = splitData['createdBy'] as String?;
                  String createdTime =
                      (splitData['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ??
                          "Unknown";

                  return StreamBuilder<bool>(
                    stream: _isSplitSettledStream(splitId),
                    builder: (context, settleSnapshot) {
                      if (settleSnapshot.connectionState == ConnectionState.waiting)
                        return _buildShimmerCard(screenWidth, screenHeight);
                      bool isSettled = settleSnapshot.data ?? false;

                      return FadeInUp(
                        delay: Duration(milliseconds: 100 * index),
                        child: GestureDetector(
                          onTap: () {
                            print("Navigating to SplitDetailScreen with splitId: $splitId");
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) => SplitDetailScreen(splitId: splitId)))
                                .then((_) => setState(() {}));
                          },
                          child: Stack(
                            children: [
                              _buildInteractiveSplitCard(
                                context,
                                splitData['description'] ?? 'Unknown Split',
                                createdTime,
                                userPaidAmount.toStringAsFixed(2),
                                totalAmount.toStringAsFixed(2),
                                isSettled ? "Settled" : displayAmount,
                                isSettledFinancially || isSettled,
                              ),
                              Positioned(
                                top: screenHeight * 0.01,
                                right: screenWidth * 0.02,
                                child: PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.grey, size: screenWidth * 0.05),
                                  tooltip: "Options",
                                  onSelected: (value) {
                                    if (value == 'removeParticipation') {
                                      _removeMyParticipation(splitId);
                                    } else if (value == 'deleteEntireSplit' && creatorId == userId) {
                                      _deleteEntireSplit(splitId);
                                    }
                                  },
                                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'removeParticipation',
                                      child: ListTile(
                                        leading: Icon(Icons.person_remove, color: Colors.red),
                                        title: Text("Remove My Participation",
                                            style: TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                    if (creatorId == userId)
                                      PopupMenuItem<String>(
                                        value: 'deleteEntireSplit',
                                        child: ListTile(
                                          leading: Icon(Icons.delete_forever, color: Colors.red),
                                          title: Text("Delete Entire Split",
                                              style: TextStyle(color: Colors.red)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _buildSplitsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('splits')
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true);

    if (widget.category != null) query = query.where('category', isEqualTo: widget.category);

    return query.snapshots();
  }

  Future<List<QueryDocumentSnapshot>> _filterSplits(List<QueryDocumentSnapshot> splits) async {
    List<QueryDocumentSnapshot> filteredSplits = [];

    for (var splitDoc in splits) {
      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
      List<dynamic> participants = splitData['participants'] as List<dynamic>;
      String splitCategory = splitData['category'] ?? 'Others';
      Map<String, dynamic> paidBy = splitData['paidBy'] as Map<String, dynamic>? ?? {};
      double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
      double userPaidAmount = paidBy[userId]?.toDouble() ?? 0.0;
      double sharePerPerson = totalAmount / participants.length;
      double netAmount = sharePerPerson - userPaidAmount;
      bool isSettled = (splitData['paidBy'] as Map<String, dynamic>?)?.entries
          .every((entry) => (entry.value as num?)?.toDouble() == totalAmount / participants.length) ??
          false;

      if (widget.friendUid != null && !participants.contains(widget.friendUid)) continue;

      if (widget.category != null && splitCategory != widget.category) continue;

      if (widget.isPayer == true) {
        bool isPayer = await _isUserPayerInTransactions(splitDoc.id);
        if (!isPayer) continue;
      }

      if (widget.isReceiver == true) {
        bool isReceiver = await _isUserReceiverInTransactions(splitDoc.id);
        if (!isReceiver) continue;
      }

      if (!showSettled && isSettled) continue;

      if (searchQuery.isNotEmpty) {
        String description = splitData['description']?.toString().toLowerCase() ?? '';
        if (!description.contains(searchQuery.toLowerCase())) continue;
      }

      filteredSplits.add(splitDoc);
    }

    return filteredSplits;
  }

  void _showSearchBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Search Splits",
            style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(
              hintText: "Enter split description...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03))),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
          TextButton(
              onPressed: () => {setState(() {}), Navigator.pop(context)},
              child: Text("Apply", style: GoogleFonts.poppins(color: Colors.blue))),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Filter Splits",
            style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title:
                Text("Show Settled Splits", style: GoogleFonts.poppins(fontSize: screenWidth * 0.04)),
                value: showSettled,
                onChanged: (value) => setState(() => showSettled = value ?? true),
                activeColor: const Color(0xFF234567),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
          TextButton(
              onPressed: () => {setState(() {}), Navigator.pop(context)},
              child: Text("Apply", style: GoogleFonts.poppins(color: Colors.blue))),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(double screenWidth, double screenHeight) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 600 ? 3 : 2,
          mainAxisSpacing: screenWidth * 0.03,
          crossAxisSpacing: screenWidth * 0.03,
          mainAxisExtent: screenHeight * 0.15),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(0, 3))
              ]),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(screenWidth * 0.04)),
          height: screenHeight * 0.15,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildInteractiveSplitCard(
      BuildContext context,
      String title,
      String createdTime,
      String paidAmount,
      String totalAmount,
      String netAmountOrSettled,
      bool settled,
      ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeInUp(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
        shadowColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(screenWidth * 0.04)),
          child: ListTile(
            contentPadding:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
            leading: CircleAvatar(
              radius: screenWidth * 0.06,
              backgroundColor: Colors.white,
              child: Icon(Icons.receipt, color: Colors.black87, size: screenWidth * 0.05),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                SizedBox(height: screenHeight * 0.005),
                Text("Created: $createdTime",
                    style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                Text("Paid: ₹$paidAmount | Total: ₹$totalAmount",
                    style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  netAmountOrSettled,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: netAmountOrSettled == "Settled"
                        ? Colors.green
                        : netAmountOrSettled.startsWith('+')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                if (settled)
                  Icon(Icons.flash_on, color: Colors.amber, size: screenWidth * 0.045),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stream<bool> _isSplitSettledStream(String splitId) {
    return FirebaseFirestore.instance
        .collection('splits')
        .doc(splitId)
        .collection('settle')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? (snapshot.get('settled') as bool? ?? false) : false)
        .handleError((error) => false);
  }

  Future<bool> _checkTransactionSettledStatus(String splitId) async {
    try {
      DocumentSnapshot settleDoc = await FirebaseFirestore.instance
          .collection('splits')
          .doc(splitId)
          .collection('settle')
          .doc(userId)
          .get();
      if (!settleDoc.exists) return false;

      bool? splitSettled = settleDoc.get('settled') as bool?;
      if (splitSettled != null) return splitSettled;

      QuerySnapshot transactionSettleSnapshot = await FirebaseFirestore.instance
          .collection('splits')
          .doc(splitId)
          .collection('settle')
          .doc(userId)
          .collection('transactions')
          .get();
      if (transactionSettleSnapshot.docs.isEmpty) return false;
      return transactionSettleSnapshot.docs.every((doc) => doc.get('settled') as bool? ?? false);
    } catch (e) {
      return false;
    }
  }
}