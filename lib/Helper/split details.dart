import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class SplitDetailScreen extends StatefulWidget {
  final String splitId;

  const SplitDetailScreen({super.key, required this.splitId});

  @override
  State<SplitDetailScreen> createState() => _SplitDetailScreenState();
}

class _SplitDetailScreenState extends State<SplitDetailScreen> {
  Map<String, dynamic>? splitData;
  bool _isLoading = true;
  Map<String, String> userNames = {};
  double totalReceive = 0.0;
  double totalPay = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSplitData();
  }

  Future<void> _fetchSplitData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot splitDoc = await FirebaseFirestore.instance.collection('splits').doc(widget.splitId).get();
      if (splitDoc.exists) {
        splitData = splitDoc.data() as Map<String, dynamic>;
        List<String> uids = [splitData!['createdBy'], ...splitData!['participants'] as List];
        for (String uid in uids.toSet()) {
          userNames[uid] = await _getUserName(uid);
        }
        _calculateBalances();
        setState(() => _isLoading = false);
      } else {
        setState(() {
          splitData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("⚠ Error fetching split data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _calculateBalances() {
    totalReceive = 0.0;
    totalPay = 0.0;
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);
    double splitAmount = (splitData!['totalAmount'] as num).toDouble() / participants.length;

    for (String uid in participants) {
      double paidAmount = (paidBy[uid] as num?)?.toDouble() ?? 0.0;
      double netAmount = splitAmount - paidAmount;
      if (netAmount > 0) {
        totalReceive += netAmount;
      } else {
        totalPay += netAmount.abs();
      }
    }
  }


  Future<String> _getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (userDoc.data() as Map<String, dynamic>?)?['name'] ?? "Unknown ($uid)";
    } catch (e) {
      return "Unknown ($uid)";
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.grey))
          : splitData == null
          ? const Center(child: Text("Split not found", style: TextStyle(fontSize: 20, color: Colors.grey)))
          : Stack(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: screenHeight * 0.02),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(screenWidth, screenHeight),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInUp(child: _buildSummaryCard(screenWidth, screenHeight)),
                        SizedBox(height: screenHeight * 0.02),
                        FadeInUp(child: _buildParticipantsCard(screenWidth)),
                        SizedBox(height: screenHeight * 0.02),
                        FadeInUp(child: _buildTransactionsCard(screenWidth)),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchSplitData,
        backgroundColor: Color(0xFF234567),
        child: const Icon(LucideIcons.refreshCw, color: Colors.white),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(double screenWidth, double screenHeight) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: screenHeight * 0.28,
      backgroundColor: Colors.white,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final collapseProgress = (screenHeight * 0.28 - constraints.biggest.height) / (screenHeight * 0.28 - kToolbarHeight);
          final cardAnimationProgress = collapseProgress.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            title: null,
            background: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF234567),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.1),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.01),
                  child: Transform.translate(
                    offset: Offset(0, cardAnimationProgress * screenHeight * 0.06),
                    child: Transform.scale(
                      scale: 1.0 - cardAnimationProgress * 0.1,
                      child: _buildTotalAmountCard(screenWidth, screenHeight),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTotalAmountCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 12,
      shadowColor: Colors.grey.shade200.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Total Amount",
              style: TextStyle(fontSize: screenWidth > 600 ? 20 : 16, color: Colors.grey.shade700),
            ),
            Text(
              "₹${(splitData!['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
              style: TextStyle(
                fontSize: screenWidth > 600 ? 40 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("Receive", style: TextStyle(fontSize: 14, color: Colors.green.shade700)),
                    Text("₹${totalReceive.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(height: 20, child: VerticalDivider(color: Colors.grey.shade300)),
                Column(
                  children: [
                    Text("Pay", style: TextStyle(fontSize: 14, color: Colors.red.shade700)),
                    Text("₹${totalPay.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSummaryCard(double screenWidth, double screenHeight) {
    Timestamp? createdAt = splitData!['createdAt'] as Timestamp?;
    String formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
        : "Unknown Date";

    return Card(
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25))),
      shadowColor: Colors.grey.shade200.withOpacity(0.3),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.info, color: Colors.black87, size: 24),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            _buildSummaryRow(
              "Category",
              splitData!['category'] ?? "Others",
              Colors.grey.shade600,
              LucideIcons.tag, // Added Tag Icon for Category
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              // Added padding for visual separation
              child: _buildEnhancedSummaryRow(
                // Using enhanced row for Created By
                "Created By",
                userNames[splitData!['createdBy']] ?? "Unknown",
                LucideIcons.user, // Added User Icon
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // Added padding for visual separation
              child: _buildEnhancedSummaryRow( // Using enhanced row for Date
                "Date",
                formattedDate,
                LucideIcons.calendar, // Added Calendar Icon
              ),
            ),
            _buildSummaryRow(
              "Participants",
              "${splitData!['participants'].length}",
              Colors.grey.shade600,
              LucideIcons.users, // Added Users Icon for Participants
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value,
      Color color,
      IconData iconData, // Added IconData parameter
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Increased vertical padding for all rows
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(iconData, color: Colors.grey.shade500, size: 20), // Added Icon at the beginning
          SizedBox(width: 8), // Spacing between icon and label
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

// Enhanced Summary Row with Icon and different text styles
  Widget _buildEnhancedSummaryRow(String label, String value, IconData iconData) {
    // Split the formatted date string to style date and time separately
    List<String> dateTimeParts = value.split(', ');
    String datePart = dateTimeParts.isNotEmpty ? dateTimeParts[0] : "";
    String timePart = dateTimeParts.length > 1 ? dateTimeParts[1] : "";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically in the center
      children: [
        Icon(iconData, color: Colors.grey.shade500, size: 20),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        RichText(
          // Using RichText for different styles within the same line
          textAlign: TextAlign.right,
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            // Default style
            children: <TextSpan>[
              TextSpan(text: datePart, style: const TextStyle(fontWeight: FontWeight.w600)),
              // Bold date part
              if (timePart.isNotEmpty)
              // Conditionally add time part if available
                TextSpan(text: ', ', style: TextStyle(color: Colors.grey.shade700)),
              // Separator with different color
              TextSpan(text: timePart, style: TextStyle(color: Colors.grey.shade700)),
              // Time part with different color
            ],
          ),
        ),
      ],
    );
  }

// Enhanced Summary Row with Icon and different text styles


  Widget _buildParticipantsCard(double screenWidth) {
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.grey.shade200.withOpacity(0.4),
      color: Colors.grey.shade200,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.users, color: Colors.black87, size: 24),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  "Participants",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            ...participants.asMap().entries.map((entry) {
              int index = entry.key;
              String uid = entry.value;
              String name = userNames[uid] ?? "Loading...";
              double paidAmount = (paidBy[uid] as num?)?.toDouble() ?? 0.0;
              double share = (splitData!['totalAmount'] as num) / participants.length;
              double netAmount = share - paidAmount;
              Color amountColor = netAmount > 0 ? Colors.red.shade600 : Colors.green.shade600;

              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.06,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            Text(
                              "Paid: ₹${paidAmount.toStringAsFixed(2)}",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            netAmount > 0 ? "-₹${netAmount.toStringAsFixed(2)}" : "+₹${(-netAmount).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: amountColor,
                            ),
                          ),
                          Text(
                            netAmount > 0 ? "Owes" : "Gets",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsCard(double screenWidth) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.grey.shade200.withOpacity(0.4),
      color: Colors.grey.shade200,
      child: Container(
        decoration:  BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.arrowRightCircle, color: Colors.black87, size: 24),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  "Transactions to Settle",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('splits')
                  .doc(widget.splitId)
                  .collection('transactions')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.grey));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "No transactions to settle.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> data = entry.value.data() as Map<String, dynamic>;
                    String fromName = userNames[data['from']] ?? "Unknown";
                    String toName = userNames[data['to']] ?? "Unknown";
                    double amount = (data['amount'] as num).toDouble();

                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.arrowRight, color: Colors.black87, size: 20),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$fromName",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                  ),
                                  Text(
                                    "to $toName",
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "₹${amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}