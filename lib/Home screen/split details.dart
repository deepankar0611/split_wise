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
import 'package:split_wise/Home%20screen/upi%20payment.dart';

import '../Helper/FCM Service.dart';

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
  Map<String, String> userTokens = {};
  double totalReceive = 0.0;
  double totalPay = 0.0;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';

  @override
  void initState() {
    super.initState();
    _fetchSplitData();
    _preloadUserTokens();
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
        List<String> uids = [splitData!['createdBy'], ...splitData!['participants'] as List];
        for (String uid in uids.toSet()) {
          userNames[uid] = await _getUserName(uid);
        }
        _calculateBalances();
      } else {
        splitData = {};
      }
    } catch (e) {
      print("⚠ Error fetching split data: $e");
      splitData = {};
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getProfileImageUrl(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (userDoc.data() as Map<String, dynamic>?)?['profileImageUrl'] ??
          'https://via.placeholder.com/150';
    } catch (e) {
      print("Error fetching profile image URL for UID $uid: $e");
      return 'https://via.placeholder.com/150';
    }
  }

  void _calculateBalances() {
    if (splitData == null || splitData!.isEmpty) return;
    totalReceive = 0.0;
    totalPay = 0.0;
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);
    double splitAmount = (splitData!['totalAmount'] as num).toDouble() / participants.length;

    if (participants.contains(userId)) {
      double paidAmount = (paidBy[userId] as num?)?.toDouble() ?? 0.0;
      double netAmount = splitAmount - paidAmount;

      if (netAmount > 0) {
        totalPay = netAmount;
        totalReceive = 0.0;
      } else if (netAmount < 0) {
        totalReceive = netAmount.abs();
        totalPay = 0.0;
      }
    }
  }

  Future<String> _getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (userDoc.data() as Map<String, dynamic>?)?['name'] ?? "Unknown ($uid)";
    } catch (e) {
      return "Unknown ($uid)";
    }
  }

  Future<void> _sendReminder() async {
    if (splitData == null || splitData!.isEmpty) return;
    try {
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

      String senderName = userNames[userId] ?? "Unknown";
      String description = splitData!['description'] ?? 'No description';
      double totalAmount = (splitData!['totalAmount'] as num).toDouble();
      int participantCount = (splitData!['participants'] as List).length;
      double share = totalAmount / participantCount;

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

  Future<void> _settleSplit() async {
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
        await userRef.update({'amountToPay': newAmountToPay});
      } else if (totalReceive > 0) {
        double newAmountToReceive = (currentAmountToReceive - totalReceive).clamp(0, double.infinity);
        await userRef.update({'amountToReceive': newAmountToReceive});
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

  Future<void> _generatePdf() async {
    if (splitData == null || splitData!.isEmpty) return;
    final pdf = pw.Document();

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

    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    List<String> participants = List<String>.from(splitData!['participants']);
    double totalAmount = (splitData!['totalAmount'] as num).toDouble();
    double sharePerPerson = totalAmount / participants.length;

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

    final directory = await getExternalStorageDirectory();
    final file = File("${directory!.path}/split_${widget.splitId}_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF saved to ${file.path}", style: GoogleFonts.poppins())),
    );
  }

  bool _isUserInvolvedInTransactions() {
    return splitData?['participants']?.contains(userId) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFF234567),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.grey))
          : splitData!.isEmpty
          ? Center(
        child: Text(
          "Split not found",
          style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.grey),
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
                        Stack(
                          children: [
                            FadeInUp(child: _buildSummaryCard(screenWidth, screenHeight)),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: FloatingActionButton(
                                heroTag: "generatePdfFab",
                                onPressed: _generatePdf,
                                mini: true,
                                backgroundColor: const Color(0xFF234567),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                tooltip: 'Generate PDF',
                                child: Icon(Icons.picture_as_pdf,
                                    color: Colors.white, size: screenWidth * 0.05),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        FadeInUp(child: _buildParticipantsCard(screenWidth, screenHeight)),
                        SizedBox(height: screenHeight * 0.02),
                        FadeInUp(child: _buildTransactionsCard(screenWidth, screenHeight)),
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
      floatingActionButton: (splitData != null &&
          splitData!.isNotEmpty &&
          splitData!['participants'].length > 1)
          ? FloatingActionButton.extended(
        heroTag: "remindFab",
        onPressed: _sendReminder,
        backgroundColor: const Color(0xFF234567),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        icon: Icon(LucideIcons.bell, color: Colors.white, size: screenWidth * 0.06),
        label: Text("Remind All",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  SliverAppBar _buildSliverAppBar(double screenWidth, double screenHeight) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: screenHeight * 0.25,
      backgroundColor: Color(0xFF234567),
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
          final collapseProgress =
              (screenHeight * 0.22 - constraints.biggest.height) / (screenHeight * 0.22 - kToolbarHeight);
          final cardAnimationProgress = collapseProgress.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.07),
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
                    offset: Offset(0, cardAnimationProgress * screenHeight * 0.04),
                    child: Transform.scale(
                      scale: 1.0 - cardAnimationProgress * 0.05,
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
        icon: Icon(LucideIcons.arrowLeft, color: Colors.black87, size: screenWidth * 0.06),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTotalAmountCard(double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withOpacity(0.6),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.015,
          vertical: screenHeight * 0.002,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics_outlined, color: const Color(0xFF234567), size: screenWidth * 0.035),
                SizedBox(width: screenWidth * 0.005),
                Flexible(
                  child: Text(
                    "Total Amount",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: (screenWidth * 0.035).clamp(12, 16),
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.002),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "₹${(splitData!['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                style: GoogleFonts.poppins(
                  fontSize: (screenWidth * 0.055).clamp(16, 24),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF234567),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.005),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.red.shade700, size: screenWidth * 0.035),
                        Text(
                          "Pay",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: (screenWidth * 0.028).clamp(10, 14),
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          "₹${totalPay.toStringAsFixed(2)}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: (screenWidth * 0.03).clamp(12, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: screenHeight * 0.02,
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.grey.shade300, width: 0.8)),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.green.shade700, size: screenWidth * 0.035),
                        Text(
                          "Receive",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: (screenWidth * 0.028).clamp(10, 14),
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          "₹${totalReceive.toStringAsFixed(2)}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: (screenWidth * 0.03).clamp(12, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.025),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCardHeader(screenWidth, LucideIcons.info, "Split Summary", const Color(0xFF234567)),
            SizedBox(height: screenHeight * 0.015),
            _buildSummaryRow(screenWidth, "Category", splitData!['category'] ?? "Others",
                const Color(0xFF757575), LucideIcons.tag),
            SizedBox(height: screenHeight * 0.01),
            _buildEnhancedSummaryRow(screenWidth, "Created By", userNames[splitData!['createdBy']] ?? "Unknown",
                const Color(0xFF757575), LucideIcons.user),
            SizedBox(height: screenHeight * 0.01),
            _buildEnhancedSummaryRow(screenWidth, "Date", formattedDate,
                const Color(0xFF757575), LucideIcons.calendar),
            SizedBox(height: screenHeight * 0.01),
            _buildSummaryRow(screenWidth, "Participants", "$participantCount",
                const Color(0xFF757575), LucideIcons.users),
            SizedBox(height: screenHeight * 0.01),
            _buildSummaryRow(screenWidth, "Per Person", "₹${amountPerPerson.toStringAsFixed(2)}",
                const Color(0xFF757575), LucideIcons.dollarSign),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(double screenWidth, IconData iconData, String title, Color? iconColor) {
    return Row(
      children: [
        Icon(iconData, size: screenWidth * 0.06, color: iconColor ?? Colors.grey.shade700),
        SizedBox(width: screenWidth * 0.02),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(double screenWidth, String label, String value, Color color, IconData iconData) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      child: Row(
        children: [
          Icon(iconData, color: const Color(0xFF234567), size: screenWidth * 0.045),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: screenWidth * 0.038, color: color, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryRow(double screenWidth, String label, String value, Color color, IconData iconData) {
    List<String> dateTimeParts = value.contains(', ') ? value.split(', ') : [value];
    String mainPart = dateTimeParts.isNotEmpty ? dateTimeParts[0] : "";
    String secondaryPart = dateTimeParts.length > 1 ? dateTimeParts[1] : "";

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      child: Row(
        children: [
          Icon(iconData, color: const Color(0xFF234567), size: screenWidth * 0.045),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.038, color: color, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: screenWidth * 0.038, color: Colors.black87),
                children: <TextSpan>[
                  TextSpan(text: mainPart, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (secondaryPart.isNotEmpty)
                    TextSpan(
                      text: ', $secondaryPart',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(double screenWidth, double screenHeight) {
    List<dynamic> participants = splitData!['participants'] as List<dynamic>;
    Map<String, dynamic> paidBy = splitData!['paidBy'] as Map<String, dynamic>? ?? {};
    double totalAmount = (splitData!['totalAmount'] as num).toDouble();
    double sharePerPerson = totalAmount / participants.length;

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.shade200.withOpacity(0.3),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(screenWidth, LucideIcons.users, "Participants", null),
            SizedBox(height: screenHeight * 0.02),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 20),
              itemBuilder: (context, index) {
                String participantUid = participants[index];
                double paidAmount = (paidBy[participantUid] as num?)?.toDouble() ?? 0.0;
                double netAmount = sharePerPerson - paidAmount;
                return _buildParticipantRow(screenWidth, screenHeight, participantUid, paidAmount, netAmount);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(
      double screenWidth, double screenHeight, String participantUid, double paidAmount, double netAmount) {
    return FutureBuilder<String>(
      future: _getUserName(participantUid),
      builder: (context, snapshot) {
        String userName = snapshot.data ?? "Loading...";
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    radius: screenWidth * 0.035,
                    child: FutureBuilder<String?>(
                      future: _getProfileImageUrl(participantUid),
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState == ConnectionState.done) {
                          String? imageUrl = imageSnapshot.data;
                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            return ClipOval(
                              child: Image.network(
                                imageUrl,
                                width: screenWidth * 0.07,
                                height: screenWidth * 0.07,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(LucideIcons.user,
                                      size: screenWidth * 0.04, color: Colors.white);
                                },
                              ),
                            );
                          }
                        }
                        return Icon(LucideIcons.user, size: screenWidth * 0.04, color: Colors.white);
                      },
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Flexible(
                    child: Text(
                      userName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: screenWidth * 0.042, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  netAmount == 0
                      ? "Settled Up"
                      : (netAmount > 0
                      ? "-₹${netAmount.toStringAsFixed(2)}"
                      : "+₹${(netAmount.abs()).toStringAsFixed(2)}"),
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: netAmount == 0
                        ? Colors.green.shade600
                        : (netAmount > 0 ? Colors.red.shade700 : Colors.green.shade700),
                  ),
                ),
                if (participantUid != userId && netAmount > 0) ...[
                  SizedBox(width: screenWidth * 0.03),
                  // GestureDetector(
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => UPIPaymentScreen(
                  //           splitId: widget.splitId,
                  //           amountToPay: netAmount,
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(
                  //       horizontal: screenWidth * 0.02,
                  //       vertical: screenHeight * 0.005,
                  //     ),
                  //     decoration: BoxDecoration(
                  //       color: const Color(0xFF234567),
                  //       borderRadius: BorderRadius.circular(6),
                  //     ),
                  //     child: Text(
                  //       "Pay Now",
                  //       style: GoogleFonts.poppins(
                  //         fontSize: screenWidth * 0.035,
                  //         fontWeight: FontWeight.w600,
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionsCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.shade200.withOpacity(0.3),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardHeader(screenWidth, LucideIcons.list, "Transactions", null),
                _buildSettleButton(screenWidth, screenHeight),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            _buildTransactionsList(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildSettleButton(double screenWidth, double screenHeight) {
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
          onTap: isSplitSettled || !_isUserInvolvedInTransactions() ? null : _settleSplit,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: isSplitSettled || !_isUserInvolvedInTransactions()
                  ? Colors.grey.shade300
                  : const Color(0xFF234567),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isSplitSettled ? "Settled" : "Settle",
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: isSplitSettled || !_isUserInvolvedInTransactions()
                    ? Colors.grey.shade600
                    : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(double screenWidth, double screenHeight) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('splits')
          .doc(widget.splitId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
            child: Center(
              child: Text("No transactions yet.",
                  style: GoogleFonts.poppins(color: Colors.grey.shade500)),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 20),
          itemBuilder: (context, index) {
            Map<String, dynamic> transaction = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildTransactionRow(screenWidth, transaction);
          },
        );
      },
    );
  }

  Widget _buildTransactionRow(double screenWidth, Map<String, dynamic> transaction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FutureBuilder<String>(
              future: _getUserName(transaction['from']),
              builder: (context, snapshotFrom) {
                String fromUserName = snapshotFrom.data ?? "Loading...";
                return Text(
                  fromUserName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
          Icon(LucideIcons.arrowRight, size: screenWidth * 0.04, color: Colors.grey.shade500),
          Expanded(
            child: FutureBuilder<String>(
              future: _getUserName(transaction['to']),
              builder: (context, snapshotTo) {
                String toUserName = snapshotTo.data ?? "Loading...";
                return Text(
                  toUserName,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Text(
            "₹${(transaction['amount'] as num).toDouble().toStringAsFixed(2)}",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.04),
          ),
        ],
      ),
    );
  }
}