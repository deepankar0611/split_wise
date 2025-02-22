import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:split_wise/Home%20screen/split%20details.dart';

class ExpenseHistoryDetailedScreen extends StatefulWidget {
  final String? friendUid;
  final String? category;
  final bool? isPayer; // Flag for payer transactions
  final bool? isReceiver; // New flag for receiver transactions

  const ExpenseHistoryDetailedScreen({super.key, this.friendUid, this.category, this.isPayer, this.isReceiver, required String showFilter});

  @override
  State<ExpenseHistoryDetailedScreen> createState() => _ExpenseHistoryDetailedScreenState();
}

class _ExpenseHistoryDetailedScreenState extends State<ExpenseHistoryDetailedScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  String searchQuery = "";
  bool showSettled = true;
  String? friendName;

  @override
  void initState() {
    super.initState();
    print("Initializing with friendUid: ${widget.friendUid}, category: ${widget.category}, isPayer: ${widget.isPayer}, isReceiver: ${widget.isReceiver}");
    if (widget.friendUid != null) _fetchFriendName();
  }

  Future<void> _fetchFriendName() async {
    try {
      DocumentSnapshot friendDoc = await FirebaseFirestore.instance.collection('users').doc(widget.friendUid!).get();
      if (friendDoc.exists) setState(() => friendName = (friendDoc.data() as Map<String, dynamic>?)?['name'] ?? "Friend");
    } catch (e) {
      print("Error fetching friend name: $e");
      setState(() => friendName = "Friend");
    }
  }

  Future<void> _removeMyParticipation(String splitId) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Removal", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to remove your participation from this split? This won’t affect other participants.", style: GoogleFonts.poppins(fontSize: 16)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Remove", style: GoogleFonts.poppins(color: Colors.red))),
          ],
        ),
      );

      if (confirm != true) return;

      DocumentSnapshot splitDoc = await FirebaseFirestore.instance.collection('splits').doc(splitId).get();
      if (!splitDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Split not found.", style: GoogleFonts.poppins())));
        return;
      }

      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(splitData['participants'] ?? []);
      Map<String, dynamic> paidBy = Map<String, dynamic>.from(splitData['paidBy'] ?? {});

      if (!participants.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You are not part of this split.", style: GoogleFonts.poppins())));
        return;
      }

      participants.remove(userId);
      paidBy.remove(userId);

      await FirebaseFirestore.instance.collection('splits').doc(splitId).update({
        'participants': participants,
        'paidBy': paidBy.isEmpty ? FieldValue.delete() : paidBy,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Your participation has been removed.", style: GoogleFonts.poppins())));
    } catch (e) {
      print("Error removing participation: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to remove participation: $e", style: GoogleFonts.poppins())));
    }
  }

  Future<void> _deleteEntireSplit(String splitId) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Delete", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete this split entirely? This will remove it for all participants.", style: GoogleFonts.poppins(fontSize: 16)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red))),
          ],
        ),
      );

      if (confirm != true) return;

      DocumentSnapshot splitDoc = await FirebaseFirestore.instance.collection('splits').doc(splitId).get();
      if (!splitDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Split not found.", style: GoogleFonts.poppins())));
        return;
      }

      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
      String? creatorId = splitData['createdBy'] as String?;

      if (creatorId != userId) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Only the creator can delete this split entirely.", style: GoogleFonts.poppins())));
        return;
      }

      await FirebaseFirestore.instance.collection('splits').doc(splitId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Split has been deleted for all participants.", style: GoogleFonts.poppins())));
      setState(() {});
    } catch (e) {
      print("Error deleting split: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete split: $e", style: GoogleFonts.poppins())));
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
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

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
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 24),
        ),
        backgroundColor: const Color(0xFF234567),
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: widget.friendUid != null
            ? [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () => _showSearchBar(context)),
          IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: () => _showFilterDialog(context)),
        ]
            : null,
      ),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.grey[100]!], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _buildSplitsStream(),
                      builder: (context, snapshot) {
                        print("StreamBuilder state: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, error=${snapshot.error}");
                        if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerGrid(screenWidth, screenHeight);
                        if (snapshot.hasError) {
                          print("Stream error: ${snapshot.error}");
                          return Center(child: Text("Error: ${snapshot.error}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          print("No splits found for userId=$userId, friendUid=${widget.friendUid}, category=${widget.category}, isPayer=${widget.isPayer}, isReceiver=${widget.isReceiver}");
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
                              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]!),
                            ),
                          );
                        }

                        var splits = snapshot.data!.docs;
                        print("Total splits before filtering: ${splits.length}");

                        return FutureBuilder<List<QueryDocumentSnapshot>>(
                          future: _filterSplits(splits),
                          builder: (context, futureSnapshot) {
                            if (futureSnapshot.connectionState == ConnectionState.waiting) return _buildShimmerGrid(screenWidth, screenHeight);
                            if (futureSnapshot.hasError) return Center(child: Text("Error: ${futureSnapshot.error}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)));
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
                                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]!),
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
                                String displayAmount = netAmount >= 0 ? "-₹${netAmount.toStringAsFixed(2)}" : "+₹${(-netAmount).toStringAsFixed(2)}";
                                bool isSettledFinancially = netAmount.abs() < 0.01;
                                String? creatorId = splitData['createdBy'] as String?;
                                String createdTime = (splitData['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? "Unknown";

                                return StreamBuilder<bool>(
                                  stream: _isSplitSettledStream(splitId),
                                  builder: (context, settleSnapshot) {
                                    if (settleSnapshot.connectionState == ConnectionState.waiting) return _buildShimmerCard(screenWidth, screenHeight);
                                    bool isSettled = settleSnapshot.data ?? false;

                                    return FadeInUp(
                                      delay: Duration(milliseconds: 100 * index),
                                      child: GestureDetector(
                                        onTap: () {
                                          print("Navigating to SplitDetailScreen with splitId: $splitId");
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => SplitDetailScreen(splitId: splitId))).then((_) => setState(() {}));
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
                                              top: 8,
                                              right: 8,
                                              child: PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                                tooltip: "Options",
                                                onSelected: (value) {
                                                  if (value == 'removeParticipation') {
                                                    _removeMyParticipation(splitId);
                                                  } else if (value == 'deleteEntireSplit' && creatorId == userId) {
                                                    _deleteEntireSplit(splitId);
                                                  }
                                                },
                                                itemBuilder: (context) => <PopupMenuEntry<String>>[
                                                  const PopupMenuItem<String>(
                                                    value: 'removeParticipation',
                                                    child: ListTile(
                                                      leading: Icon(Icons.person_remove, color: Colors.red),
                                                      title: Text("Remove My Participation", style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ),
                                                  if (creatorId == userId)
                                                    const PopupMenuItem<String>(
                                                      value: 'deleteEntireSplit',
                                                      child: ListTile(
                                                        leading: Icon(Icons.delete_forever, color: Colors.red),
                                                        title: Text("Delete Entire Split", style: TextStyle(color: Colors.red)),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildSplitsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('splits').where('participants', arrayContains: userId).orderBy('createdAt', descending: true);

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
      bool isSettled = (splitData['paidBy'] as Map<String, dynamic>?)?.entries.every((entry) => (entry.value as num?)?.toDouble() == totalAmount / participants.length) ?? false;

      // Apply friend filter
      if (widget.friendUid != null && !participants.contains(widget.friendUid)) continue;

      // Apply category filter
      if (widget.category != null && splitCategory != widget.category) continue;

      // Apply payer filter
      if (widget.isPayer == true) {
        bool isPayer = await _isUserPayerInTransactions(splitDoc.id);
        if (!isPayer) continue;
      }

      // Apply receiver filter
      if (widget.isReceiver == true) {
        bool isReceiver = await _isUserReceiverInTransactions(splitDoc.id);
        if (!isReceiver) continue;
      }

      // Apply settled filter
      if (!showSettled && isSettled) continue;

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        String description = splitData['description']?.toString().toLowerCase() ?? '';
        if (!description.contains(searchQuery.toLowerCase())) continue;
      }

      filteredSplits.add(splitDoc);
    }

    return filteredSplits;
  }

  void _showSearchBar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Search Splits", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(hintText: "Enter split description...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
          TextButton(onPressed: () => {setState(() {}), Navigator.pop(context)}, child: Text("Apply", style: GoogleFonts.poppins(color: Colors.blue))),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Filter Splits", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: Text("Show Settled Splits", style: GoogleFonts.poppins()),
                value: showSettled,
                onChanged: (value) => setState(() => showSettled = value ?? true),
                activeColor: const Color(0xFF234567),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue))),
          TextButton(onPressed: () => {setState(() {}), Navigator.pop(context)}, child: Text("Apply", style: GoogleFonts.poppins(color: Colors.blue))),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(double screenWidth, double screenHeight) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 120),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 7, offset: const Offset(0, 3))]),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.teal.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(15)),
          height: 120,
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
    return FadeInUp(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        shadowColor: Colors.teal.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.teal.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04, vertical: MediaQuery.of(context).size.height * 0.01),
            leading: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.06,
              backgroundColor: Colors.teal.shade100,
              child: Icon(Icons.receipt, color: Colors.teal.shade900, size: MediaQuery.of(context).size.width * 0.05),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 1),
                const SizedBox(height: 4),
                Text("Created: $createdTime", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
                Text("Paid: ₹$paidAmount | Total: ₹$totalAmount", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  netAmountOrSettled,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: netAmountOrSettled == "Settled" ? Colors.green : netAmountOrSettled.startsWith('+') ? Colors.green : Colors.red,
                  ),
                ),
                if (settled) const Icon(Icons.flash_on, color: Colors.amber, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stream<bool> _isSplitSettledStream(String splitId) {
    return FirebaseFirestore.instance.collection('splits').doc(splitId).collection('settle').doc(userId).snapshots().map((snapshot) => snapshot.exists ? (snapshot.get('settled') as bool? ?? false) : false).handleError((error) => false);
  }

  Future<bool> _checkTransactionSettledStatus(String splitId) async {
    try {
      DocumentSnapshot settleDoc = await FirebaseFirestore.instance.collection('splits').doc(splitId).collection('settle').doc(userId).get();
      if (!settleDoc.exists) return false;

      bool? splitSettled = settleDoc.get('settled') as bool?;
      if (splitSettled != null) return splitSettled;

      QuerySnapshot transactionSettleSnapshot = await FirebaseFirestore.instance.collection('splits').doc(splitId).collection('settle').doc(userId).collection('transactions').get();
      if (transactionSettleSnapshot.docs.isEmpty) return false;
      return transactionSettleSnapshot.docs.every((doc) => doc.get('settled') as bool? ?? false);
    } catch (e) {
      return false;
    }
  }
}