import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';

import 'FCM Service.dart';



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
  Map<String, String> userTokens = {}; // Added for FCM tokens
  double totalReceive = 0.0;
  double totalPay = 0.0;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';

  @override
  void initState() {
    super.initState();
    _fetchSplitData();
    _preloadUserTokens(); // Preload FCM tokens
  }

  Future<void> _preloadUserTokens() async {
    var userDocs = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      for (var doc in userDocs.docs) {
        userTokens[doc.id] = doc.data()['fcmToken'] ?? '';
      }
    });
  }

  Future<void> _fetchSplitData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot splitDoc =
      await FirebaseFirestore.instance.collection('splits').doc(widget.splitId).get();
      if (splitDoc.exists) {
        splitData = splitDoc.data() as Map<String, dynamic>;
        List<String> uids = [
          splitData!['createdBy'],
          ...splitData!['participants'] as List
        ];
        for (String uid in uids.toSet()) {
          userNames[uid] = await _getUserName(uid);
        }
        _calculateBalances();
      } else {
        splitData = null;
      }
    } catch (e) {
      print("⚠ Error fetching split data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getProfileImageUrl(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (userDoc.data() as Map<String, dynamic>?)?['profileImageUrl'];
    } catch (e) {
      print("Error fetching profile image URL for UID $uid: $e");
      return null;
    }
  }

  void _calculateBalances() {
    totalReceive = 0.0;
    totalPay = 0.0;
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);
    double splitAmount = (splitData!['totalAmount'] as num).toDouble() / participants.length;

    if (participants.contains(userId)) {
      double paidAmount = (paidBy[userId] as num?)?.toDouble() ?? 0.0;
      double netAmount = splitAmount - paidAmount;

      if (netAmount > 0) {
        totalPay = netAmount; // User owes this amount
        totalReceive = 0.0;
      } else if (netAmount < 0) {
        totalReceive = netAmount.abs(); // User is owed this amount
        totalPay = 0.0;
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

  Future<void> _sendReminder() async {
    try {
      // Add reminder to Firestore
      await FirebaseFirestore.instance
          .collection('splits')
          .doc(widget.splitId)
          .collection('reminders')
          .add({
        'sentBy': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': splitData!['participants'],
        'splitTitle': splitData!['title'] ?? 'Split Payment',
        'splitId': widget.splitId,
      });

      // Fetch current user's name
      String senderName = userNames[userId] ?? "Unknown";
      String description = splitData!['description'] ?? 'No description';
      double totalAmount = (splitData!['totalAmount'] as num).toDouble();
      int participantCount = (splitData!['participants'] as List).length;
      double share = totalAmount / participantCount;

      // Send push notification to all participants except sender
      List<String> participants = List<String>.from(splitData!['participants']);
      for (String participantUid in participants) {
        if (participantUid != userId) {
          String deviceToken = userTokens[participantUid] ?? '';
          if (deviceToken.isNotEmpty) {
            await FCMService.sendPushNotification(
              deviceToken,
              "Payment Reminder",
              "$senderName requests ₹${share.toStringAsFixed(2)} for '$description'",
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder sent successfully!", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error sending reminder: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send reminder: $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Fetch transactions
    QuerySnapshot transactionSnapshot = await FirebaseFirestore.instance
        .collection('splits')
        .doc(widget.splitId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> transactions = transactionSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    // Prepare participant data
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);
    double totalAmount = (splitData!['totalAmount'] as num).toDouble();
    double sharePerPerson = totalAmount / participants.length;

    // Summary data
    Timestamp? createdAt = splitData!['createdAt'] as Timestamp?;
    String formattedDate =
    createdAt != null ? DateFormat('dd MMM, hh:mm a').format(createdAt.toDate()) : "Unknown Date";

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Text(
            splitData!['title'] ?? 'Split Details',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
          pw.Text('Category: ${splitData!['category'] ?? "Others"}'),
          pw.Text('Created By: ${userNames[splitData!['createdBy']] ?? "Unknown"}'),
          pw.Text('Date: $formattedDate'),
          pw.Text('Participants: ${participants.length}'),
          pw.Text('Amount Per Person: ₹${sharePerPerson.toStringAsFixed(2)}'),
          pw.SizedBox(height: 20),
          pw.Text('Participants', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Name', 'Paid', 'Net Amount'],
            data: participants.map((uid) {
              double paidAmount = (paidBy[uid] as num?)?.toDouble() ?? 0.0;
              double netAmount = sharePerPerson - paidAmount;
              return [
                userNames[uid] ?? "Unknown",
                '₹${paidAmount.toStringAsFixed(2)}',
                netAmount > 0 ? '-₹${netAmount.toStringAsFixed(2)}' : '+₹${(-netAmount).toStringAsFixed(2)}',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          if (transactions.isNotEmpty)
            pw.Table.fromTextArray(
              headers: ['From', 'To', 'Amount'],
              data: transactions.map((transaction) {
                return [
                  userNames[transaction['from']] ?? "Unknown",
                  userNames[transaction['to']] ?? "Unknown",
                  '₹${(transaction['amount'] as num).toDouble().toStringAsFixed(2)}',
                ];
              }).toList(),
            )
          else
            pw.Text('No transactions to settle.'),
        ],
      ),
    );

    // Save the PDF
    final directory = await getExternalStorageDirectory();
    final file = File("${directory!.path}/split_${widget.splitId}_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF saved to ${file.path}", style: GoogleFonts.poppins())),
    );
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
          ? const Center(
        child: Text(
          "Split not found",
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      )
          : Stack(
        children: [
          Container(
            margin: EdgeInsets.only(top: screenHeight * 0.02),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.01,
                    ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _generatePdf,
            backgroundColor: const Color(0xFF234567),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Generate PDF',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _fetchSplitData,
            backgroundColor: const Color(0xFF234567),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: const Icon(LucideIcons.refreshCw, color: Colors.white),
          ),
        ],
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
          final collapseProgress =
              (screenHeight * 0.28 - constraints.biggest.height) / (screenHeight * 0.28 - kToolbarHeight);
          final cardAnimationProgress = collapseProgress.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            title: null,
            background: Container(
              decoration: const BoxDecoration(color: Color(0xFF234567)),
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.1),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.01,
                  ),
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
                    Text("Pay", style: TextStyle(fontSize: 14, color: Colors.red.shade700)),
                    Text("₹${totalPay.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(height: 20, child: VerticalDivider(color: Colors.grey.shade300)),
                Column(
                  children: [
                    Text("Receive", style: TextStyle(fontSize: 14, color: Colors.green.shade700)),
                    Text("₹${totalReceive.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
        ? DateFormat('dd MMM, hh:mm a').format(createdAt.toDate())
        : "Unknown Date";

    double totalAmount = (splitData!['totalAmount'] as num).toDouble();
    int participantCount = (splitData!['participants'] as List<dynamic>).length;
    double amountPerPerson = totalAmount / participantCount;

    return Card(
      elevation: 8,
      shadowColor: Colors.grey.shade200.withOpacity(0.3),
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(screenWidth, LucideIcons.info, "Summary", null),
            SizedBox(height: screenWidth * 0.03),
            _buildSummaryRow("Category", splitData!['category'] ?? "Others",
                Colors.grey.shade600, LucideIcons.tag),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _buildEnhancedSummaryRow(
                  "Created By", userNames[splitData!['createdBy']] ?? "Unknown", LucideIcons.user),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _buildEnhancedSummaryRow("Date", formattedDate, LucideIcons.calendar),
            ),
            _buildSummaryRow("Participants", "${splitData!['participants'].length}",
                Colors.grey.shade600, LucideIcons.users),
            _buildSummaryRow("Amount Per Person", "₹${amountPerPerson.toStringAsFixed(2)}",
                Colors.grey.shade600, LucideIcons.dollarSign),
            SizedBox(height: screenWidth * 0.03),
            Center(child: _buildSendReminderButton(screenWidth)),
          ],
        ),
      ),
    );
  }

  Widget _buildSendReminderButton(double screenWidth) {
    return GestureDetector(
      onTap: splitData!['participants'].length > 1 ? _sendReminder : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
        decoration: BoxDecoration(
          color: const Color(0xFF234567),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bell, color: Colors.white, size: screenWidth * 0.05),
            SizedBox(width: screenWidth * 0.015),
            Text(
              "Send Reminder",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(iconData, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryRow(String label, String value, IconData iconData) {
    List<String> dateTimeParts = value.split(', ');
    String datePart = dateTimeParts.isNotEmpty ? dateTimeParts[0] : "";
    String timePart = dateTimeParts.length > 1 ? dateTimeParts[1] : "";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(iconData, color: Colors.grey.shade500, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            children: <TextSpan>[
              TextSpan(text: datePart, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (timePart.isNotEmpty)
                TextSpan(text: ', ', style: TextStyle(color: Colors.grey.shade700)),
              TextSpan(text: timePart, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsCard(double screenWidth) {
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);

    return Card(
      elevation: 10,
      shadowColor: Colors.grey.shade200.withOpacity(0.4),
      color: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(screenWidth, LucideIcons.users, "Participants", null),
            SizedBox(height: screenWidth * 0.03),
            ...participants.asMap().entries.map((entry) {
              int index = entry.key;
              String uid = entry.value;
              return FutureBuilder<String?>(
                future: _getProfileImageUrl(uid),
                builder: (context, profileSnapshot) {
                  String? profileImageUrl = profileSnapshot.data;
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: _buildParticipantRow(
                      screenWidth,
                      uid,
                      userNames[uid] ?? "Unknown",
                      (paidBy[uid] as num?)?.toDouble() ?? 0.0,
                      (splitData!['totalAmount'] as num) / participants.length,
                      profileImageUrl,
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(double screenWidth, String uid, String name, double paidAmount,
      double share, String? profileImageUrl) {
    double netAmount = share - paidAmount;
    Color amountColor = netAmount > 0 ? Colors.red.shade600 : Colors.green.shade600;

    return Container(
      margin: const EdgeInsets.only(top: 8),
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
            backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : const AssetImage('assets/logo/intro.jpeg') as ImageProvider,
            backgroundColor: Colors.grey.shade200,
            onBackgroundImageError: (exception, stackTrace) {
              print("Error loading profile image for UID $uid: $exception");
            },
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
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
    );
  }

  Widget _buildTransactionsCard(double screenWidth) {
    return Card(
      elevation: 10,
      shadowColor: Colors.grey.shade200.withOpacity(0.4),
      color: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              screenWidth,
              LucideIcons.arrowRightCircle,
              "Transactions to Settle",
              _buildSettleButton(),
            ),
            SizedBox(height: screenWidth * 0.03),
            _buildTransactionsList(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(double screenWidth, IconData icon, String title, Widget? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildIconContainer(screenWidth, icon),
            SizedBox(width: screenWidth * 0.02),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildIconContainer(double screenWidth, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.black87, size: 24),
    );
  }

  StreamBuilder<DocumentSnapshot<Object?>> _buildSettleButton() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('splits')
          .doc(widget.splitId)
          .collection('settle')
          .doc(userId)
          .snapshots(),
      builder: (context, settleSnapshot) {
        final isSplitSettled = settleSnapshot.data?.exists == true
            ? (settleSnapshot.data!.get('settled') as bool? ?? false)
            : false;
        if (settleSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: isSplitSettled || !isUserInvolvedInTransactions() ? null : () => _settleSplit(isSplitSettled),
          child: Text(
            isSplitSettled ? "Settled" : "Settle",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSplitSettled || !isUserInvolvedInTransactions() ? Colors.grey : Colors.blue,
            ),
          ),
        );
      },
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> _buildTransactionsList(double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
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
          return _buildEmptyTransactions();
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final transactionId = doc.id;
            final fromName = userNames[data['from']] ?? "Unknown";
            final toName = userNames[data['to']] ?? "Unknown";
            final amount = (data['amount'] as num).toDouble();
            final isUserInvolved = data['from'] == userId || data['to'] == userId;

            return FadeInUp(
              child: _buildTransactionRow(
                screenWidth,
                fromName,
                toName,
                amount,
                transactionId,
                isUserInvolved,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Container _buildEmptyTransactions() {
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

  Widget _buildTransactionRow(double screenWidth, String fromName, String toName, double amount,
      String transactionId, bool isUserInvolved) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
          _buildIconContainer(screenWidth, LucideIcons.arrowRight),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "to $toName",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          _buildSettleStatus(transactionId, isUserInvolved, amount),
        ],
      ),
    );
  }

  Widget _buildSettleStatus(String transactionId, bool isUserInvolved, double amount) {
    return isUserInvolved
        ? FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('splits')
          .doc(widget.splitId)
          .collection('settle')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .get(),
      builder: (context, settleSnapshot) {
        String settleStatus = "";
        if (settleSnapshot.connectionState == ConnectionState.waiting) {
          settleStatus = "Loading...";
        } else if (settleSnapshot.hasError) {
          settleStatus = "Error";
        } else if (settleSnapshot.hasData && settleSnapshot.data!.exists) {
          settleStatus = (settleSnapshot.data!.get('settled') as bool? ?? false) ? "Settled" : "";
        }
        return _buildAmountAndSettleStatusColumn(amount, settleStatus);
      },
    )
        : _buildAmountAndSettleStatusColumn(amount, "");
  }

  Column _buildAmountAndSettleStatusColumn(double amount, String settleStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        if (settleStatus.isNotEmpty)
          Text(
            settleStatus,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: settleStatus == "Settled" || settleStatus == "Error" ? Colors.green : Colors.blue,
            ),
          ),
      ],
    );
  }

  Future<void> _settleSplit(bool isSplitSettled) async {
    try {
      await FirebaseFirestore.instance
          .collection('splits')
          .doc(widget.splitId)
          .collection('settle')
          .doc(userId)
          .set({
        'settled': true,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

      double currentAmountToPay = (userData['amountToPay'] as num?)?.toDouble() ?? 0.0;
      double currentAmountToReceive = (userData['amountToReceive'] as num?)?.toDouble() ?? 0.0;

      if (totalPay > 0) {
        double newAmountToPay = (currentAmountToPay - totalPay).clamp(0, double.infinity);
        await userRef.update({
          'amountToPay': newAmountToPay,
        });
      } else if (totalReceive > 0) {
        double newAmountToReceive = (currentAmountToReceive - totalReceive).clamp(0, double.infinity);
        await userRef.update({
          'amountToReceive': newAmountToReceive,
        });
      }

      setState(() {
        _fetchSplitData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Split settled successfully", style: GoogleFonts.poppins())),
      );
    } catch (e) {
      print("Error settling split: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to settle split: $e", style: GoogleFonts.poppins())),
      );
    }
  }

  bool isUserInvolvedInTransactions() {
    return splitData?['participants']?.contains(userId) ?? false;
  }
}