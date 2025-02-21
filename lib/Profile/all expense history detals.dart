import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart'; // For loading animations
import '../Home screen/split details.dart';

class ExpenseHistoryDetailedScreen extends StatefulWidget {
  final String? friendUid; // Optional friendUid parameter

  const ExpenseHistoryDetailedScreen({super.key, this.friendUid});

  @override
  State<ExpenseHistoryDetailedScreen> createState() => _ExpenseHistoryDetailedScreenState();
}

class _ExpenseHistoryDetailedScreenState extends State<ExpenseHistoryDetailedScreen> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  String searchQuery = "";
  bool showSettled = true; // Filter for settled/unsettled splits
  String? friendName; // To store the friend's name

  @override
  void initState() {
    super.initState();
    if (widget.friendUid != null) {
      _fetchFriendName(); // Fetch friend name if friendUid is provided
    }
  }

  Future<void> _fetchFriendName() async {
    try {
      DocumentSnapshot friendDoc = await FirebaseFirestore.instance.collection('users').doc(widget.friendUid!).get();
      if (friendDoc.exists) {
        final data = friendDoc.data() as Map<String, dynamic>?;
        setState(() {
          friendName = data?['name'] ?? "Friend";
        });
      }
    } catch (e) {
      print("Error fetching friend name: $e");
      setState(() {
        friendName = "Friend";
      });
    }
  }

  Future<void> _removeMyParticipation(String splitId) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Removal", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to remove your participation from this split? This won’t affect other participants.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Remove", style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Fetch the split document
      DocumentSnapshot splitDoc = await FirebaseFirestore.instance.collection('splits').doc(splitId).get();
      if (!splitDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Split not found.", style: GoogleFonts.poppins())),
        );
        return;
      }

      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(splitData['participants'] ?? []);
      Map<String, dynamic> paidBy = Map<String, dynamic>.from(splitData['paidBy'] ?? {});

      // Check if user is a participant
      if (!participants.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You are not part of this split.", style: GoogleFonts.poppins())),
        );
        return;
      }

      // Remove user from participants and paidBy
      participants.remove(userId);
      paidBy.remove(userId);

      // Update the split document
      await FirebaseFirestore.instance.collection('splits').doc(splitId).update({
        'participants': participants,
        'paidBy': paidBy.isEmpty ? FieldValue.delete() : paidBy,
      });

      // Optionally, update your user document to remove this split from your history
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        // You could maintain a splits history under users/{userId}/splits/{splitId}
        // For simplicity, we’ll just remove participation here
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Your participation has been removed.", style: GoogleFonts.poppins())),
      );
    } catch (e) {
      print("Error removing participation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove participation: $e", style: GoogleFonts.poppins())),
      );
    }
  }

  Future<void> _deleteEntireSplit(String splitId) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Delete", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to delete this split entirely? This will remove it for all participants.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Fetch the split document to check if the user is the creator
      DocumentSnapshot splitDoc = await FirebaseFirestore.instance.collection('splits').doc(splitId).get();
      if (!splitDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Split not found.", style: GoogleFonts.poppins())),
        );
        return;
      }

      Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
      String? creatorId = splitData['createdBy'] as String?;

      // Check if the user is the creator
      if (creatorId != userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Only the creator can delete this split entirely.", style: GoogleFonts.poppins())),
        );
        return;
      }

      // Delete the entire split document
      await FirebaseFirestore.instance.collection('splits').doc(splitId).delete();

      // Optionally, update users' histories to reflect the deletion (if tracked)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Split has been deleted for all participants.", style: GoogleFonts.poppins())),
      );

      // Refresh the screen or pop back to update the list
      setState(() {});
    } catch (e) {
      print("Error deleting split: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete split: $e", style: GoogleFonts.poppins())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Removed 'const' to resolve shade100 error
      appBar: AppBar(
        title: Text(
          widget.friendUid != null ? "Splits with ${friendName ?? 'Friend'}" : "Expense History",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF234567),
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.friendUid != null) ...[
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                _showSearchBar(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                _showFilterDialog(context);
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[100]!], // Removed 'const' to resolve shade100 error
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: widget.friendUid != null
                          ? FirebaseFirestore.instance
                          .collection('splits')
                          .where('participants', arrayContainsAny: [userId, widget.friendUid!])
                          .snapshots()
                          : FirebaseFirestore.instance
                          .collection('splits')
                          .where('participants', arrayContains: userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildShimmerGrid(screenWidth, screenHeight);
                        }
                        if (snapshot.hasError) {
                          print("Stream error: ${snapshot.error}"); // Debug print for errors
                          return Center(
                            child: Text(
                              "Error: ${snapshot.error}",
                              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              widget.friendUid != null
                                  ? "No splits with this friend yet."
                                  : "No expense history yet.",
                              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]!),
                            ),
                          );
                        }

                        var splits = snapshot.data!.docs;
                        List<QueryDocumentSnapshot> filteredSplits = splits.where((splitDoc) {
                          Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
                          List<dynamic> participants = splitData['participants'] as List<dynamic>;
                          if (widget.friendUid != null) {
                            // Filter for splits involving both user and friend
                            if (!(participants.contains(userId) && participants.contains(widget.friendUid!))) {
                              return false;
                            }
                          }
                          double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
                          bool isSettled = (splitData['paidBy'] as Map<String, dynamic>?)?.entries.every(
                                (entry) => (entry.value as num?)?.toDouble() == totalAmount / participants.length,
                          ) ?? false;

                          if (!showSettled && isSettled) return false; // Filter out settled splits if unchecked
                          if (searchQuery.isNotEmpty) {
                            String description = splitData['description']?.toString().toLowerCase() ?? '';
                            return description.contains(searchQuery.toLowerCase());
                          }
                          return true;
                        }).toList();

                        if (filteredSplits.isEmpty) {
                          return Center(
                            child: Text(
                              widget.friendUid != null
                                  ? "No matching splits with this friend found."
                                  : "No matching splits found.",
                              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]!),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredSplits.length,
                          itemBuilder: (context, index) {
                            var splitDoc = filteredSplits[index];
                            String splitId = splitDoc.id; // Get the split ID for navigation
                            Map<String, dynamic> splitData = splitDoc.data() as Map<String, dynamic>;
                            Map<String, dynamic> paidBy = splitData['paidBy'] as Map<String, dynamic>? ?? {};
                            double totalAmount = splitData['totalAmount']?.toDouble() ?? 0.0;
                            int participantCount = (splitData['participants'] as List<dynamic>?)?.length ?? 1;
                            double userPaidAmount = (paidBy[userId] as num?)?.toDouble() ?? 0.0;

                            double sharePerPerson = totalAmount / participantCount;
                            double yourNet = sharePerPerson - userPaidAmount;
                            double netAmount = yourNet; // Simplified for user perspective
                            String displayAmount = netAmount >= 0
                                ? "-₹${netAmount.toStringAsFixed(2)}"
                                : "+₹${(-netAmount).toStringAsFixed(2)}";
                            bool isSettledFinancially = netAmount.abs() < 0.01;
                            String? creatorId = splitData['createdBy'] as String?; // Get the creator ID
                            String createdTime = (splitData['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? "Unknown";

                            return FutureBuilder<bool>(
                              future: _isSplitSettled(splitId), // Check if all transactions are settled
                              builder: (context, settleSnapshot) {
                                if (settleSnapshot.connectionState == ConnectionState.waiting) {
                                  return _buildShimmerCard(screenWidth, screenHeight); // Show shimmer while loading settle status
                                }
                                if (settleSnapshot.hasError) {
                                  print("Settle status error for split $splitId: ${settleSnapshot.error}"); // Debug print for errors
                                  return _buildInteractiveSplitCard(
                                    context,
                                    splitData['description'] ?? 'Unknown Split',
                                    createdTime,
                                    userPaidAmount.toStringAsFixed(2),
                                    totalAmount.toStringAsFixed(2),
                                    displayAmount,
                                    isSettledFinancially,
                                  );
                                }

                                bool isSettled = settleSnapshot.data ?? false;
                                print("Detailed settle status for split $splitId: isSettled=$isSettled, "
                                    "financiallySettled=$isSettledFinancially, "
                                    "user=$userId"); // Debug print

                                return FadeInUp(
                                  delay: Duration(milliseconds: 100 * index),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SplitDetailScreen(splitId: splitId),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        _buildInteractiveSplitCard(
                                          context,
                                          splitData['description'] ?? 'Unknown Split',
                                          createdTime,
                                          userPaidAmount.toStringAsFixed(2),
                                          totalAmount.toStringAsFixed(2),
                                          isSettled ? "Settled" : displayAmount, // Show "Settled" only if all transactions are settled
                                          isSettledFinancially || isSettled, // Update settled status to include manual settlement
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                            tooltip: "Options",
                                            onSelected: (String value) {
                                              if (value == 'removeParticipation') {
                                                _removeMyParticipation(splitId);
                                              } else if (value == 'deleteEntireSplit' && creatorId == userId) {
                                                _deleteEntireSplit(splitId);
                                              }
                                            },
                                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'removeParticipation',
                                                child: ListTile(
                                                  leading: Icon(Icons.person_remove, color: Colors.red),
                                                  title: Text("Remove My Participation", style: TextStyle(color: Colors.red)),
                                                ),
                                              ),
                                              if (creatorId == userId) // Only show delete option if user is the creator
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

  void _showSearchBar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Search Splits", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(
            hintText: "Enter split description...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            setState(() => searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text("Apply", style: GoogleFonts.poppins(color: Colors.blue)),
          ),
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
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text("Show Settled Splits", style: GoogleFonts.poppins()),
                  value: showSettled,
                  onChanged: (value) => setState(() => showSettled = value ?? true),
                  activeColor: const Color(0xFF234567),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text("Apply", style: GoogleFonts.poppins(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(double screenWidth, double screenHeight) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 120, // Match FriendsList card height
      ),
      itemCount: 4, // Placeholder for shimmer effect
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildShimmerCard(double screenWidth, double screenHeight) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.teal.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          height: 120, // Match mainAxisExtent from grid delegate
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.teal.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: MediaQuery.of(context).size.height * 0.01,
            ),
            leading: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.06,
              backgroundColor: Colors.teal.shade100,
              child: Icon(
                Icons.receipt, // Use an icon (e.g., receipt) as a placeholder
                color: Colors.teal.shade900,
                size: MediaQuery.of(context).size.width * 0.05,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4), // Spacing between title and details
                Text(
                  "Created: $createdTime",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  "Paid: ₹$paidAmount | Total: ₹$totalAmount",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
                    color: netAmountOrSettled == "Settled"
                        ? Colors.grey // Neutral color for settled status
                        : netAmountOrSettled.startsWith('+') ? Colors.green : Colors.red,
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

  Future<bool> _isSplitSettled(String splitId) async {
    try {
      // Check if there’s a split-level settled status
      DocumentSnapshot splitSettleDoc = await FirebaseFirestore.instance
          .collection('splits')
          .doc(splitId)
          .collection('settle')
          .doc(userId)
          .get();

      if (splitSettleDoc.exists) {
        bool splitSettled = splitSettleDoc.get('settled') as bool? ?? false;
        print("Split-level settle status for $splitId, user $userId: $splitSettled");
        return splitSettled;
      }

      // If no split-level status, check transaction-level settle status
      QuerySnapshot transactionSettleSnapshot = await FirebaseFirestore.instance
          .collection('splits')
          .doc(splitId)
          .collection('settle')
          .doc(userId)
          .collection('transactions')
          .get();

      if (transactionSettleSnapshot.docs.isEmpty) {
        print("No transaction settle data found for split $splitId, user $userId");
        return false;
      }

      // Check if ALL transactions are settled (settled: true)
      bool allSettled = transactionSettleSnapshot.docs.every((doc) =>
      doc.get('settled') as bool? ?? false);

      print("Transaction-level settle status for split $splitId, user $userId: allSettled=$allSettled");
      return allSettled;
    } catch (e) {
      print("Error checking settle status for split $splitId, user $userId: $e");
      return false; // Default to false if there’s an error
    }
  }
}