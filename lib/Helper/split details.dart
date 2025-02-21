import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart'; // For animations

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
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : splitData == null
          ? const Center(child: Text("Split not found", style: TextStyle(fontSize: 20, color: Colors.grey)))
          : CustomScrollView(
        slivers: [
          _buildSliverAppBar(screenWidth, screenHeight),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(child: _buildSummaryCard(screenWidth)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchSplitData,
        backgroundColor: Colors.teal.shade700,
        child: const Icon(LucideIcons.refreshCw, color: Colors.white),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(double screenWidth, double screenHeight) {
    return SliverAppBar(
      expandedHeight: screenHeight * 0.28,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          splitData!['description'] ?? "Unnamed Split",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.cyan.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.06),
                Text(
                  "₹${(splitData!['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 44 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 2))],
                  ),
                ),
                Text(
                  "Total Amount",
                  style: TextStyle(fontSize: screenWidth > 600 ? 20 : 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.teal.shade700,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSummaryCard(double screenWidth) {
    Timestamp? createdAt = splitData!['createdAt'] as Timestamp?;
    String formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy – HH:mm').format(createdAt.toDate())
        : "Unknown Date";

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.teal.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.info, color: Colors.teal, size: 24),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            _buildSummaryRow("Category", splitData!['category'] ?? "Others", Colors.grey.shade600),
            _buildSummaryRow("Created By", userNames[splitData!['createdBy']] ?? "Unknown", Colors.grey.shade600),
            _buildSummaryRow("Date", formattedDate, Colors.grey.shade600),
            _buildSummaryRow("Participants", "${splitData!['participants'].length}", Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

  Widget _buildParticipantsCard(double screenWidth) {
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.teal.withOpacity(0.4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.users, color: Colors.white, size: 24),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  "Participants",
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
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
                        color: Colors.teal.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.06,
                        backgroundColor: Colors.teal.shade100,
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            color: Colors.teal.shade900,
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
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
      shadowColor: Colors.teal.withOpacity(0.4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.arrowRightCircle, color: Colors.white, size: 24),
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  "Transactions to Settle",
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
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
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
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
                              color: Colors.teal.withOpacity(0.2),
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
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade300, Colors.teal.shade500],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
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