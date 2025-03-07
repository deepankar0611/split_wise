import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

import 'package:split_wise/split/friends.dart';

class FinalSplitScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPeople;
  final Map<String, double> payerAmounts; // Now expects UID keys
  final double totalAmount;
  final String expenseDescription;
  final String selectedCategory; // Added for consistency with HomeScreen

  const FinalSplitScreen({
    super.key,
    required this.selectedPeople,
    required this.payerAmounts,
    required this.totalAmount,
    required this.expenseDescription,
    required this.selectedCategory,
  });

  @override
  State<FinalSplitScreen> createState() => _FinalSplitScreenState();
}

class _FinalSplitScreenState extends State<FinalSplitScreen> {
  bool _paymentFinalized = false;

  double _calculateAmountPerPerson() {
    return widget.totalAmount / (widget.selectedPeople.length + 1); // +1 for "You"
  }

  void _handleFinalizePayment() async {
    print("🚀 Starting _handleFinalizePayment");

    setState(() {
      _paymentFinalized = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠ No user logged in");
      setState(() { _paymentFinalized = false; });
      return;
    }

    List<Map<String, dynamic>> people = [
      {"name": "You", "uid": user.uid}
    ]..addAll(widget.selectedPeople);

    Map<String, double> finalPayerAmounts = {};
    for (var person in people) {
      String uid = person['uid'];
      String name = person['name'];
      finalPayerAmounts[uid] = name == "You" && widget.payerAmounts.isEmpty
          ? widget.totalAmount
          : widget.payerAmounts[name] ?? 0.0;
    }

    List<Map<String, dynamic>> transactions = _calculateTransactions(
      people,
      _calculateAmountPerPerson(),
      finalPayerAmounts,
    );

    try {
      await _uploadSplitData(people, finalPayerAmounts, transactions);
      print("✅ Data uploaded successfully");

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() { _paymentFinalized = false; });

        // Navigate back to AddExpenseScreen and signal to reset
        Navigator.pop(context, true); // Pass true to indicate reset
      }
    } catch (e, stackTrace) {
      print("❌ Error: $e");
      print("Stack trace: $stackTrace");
      setState(() { _paymentFinalized = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to finalize payment: $e")),
        );
      }
    }
  }

  Future<void> updateUserBalance({
    required String payerUid,
    required String receiverUid,
    required double amount,
  }) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentReference payerRef = firestore.collection('users').doc(payerUid);
    DocumentReference receiverRef = firestore.collection('users').doc(receiverUid);

    try {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot payerSnapshot = await transaction.get(payerRef);
        DocumentSnapshot receiverSnapshot = await transaction.get(receiverRef);

        if (!payerSnapshot.exists || !receiverSnapshot.exists) {
          print("⚠ User document missing!");
          return;
        }

        double currentPayerAmount = (payerSnapshot.data() as Map<String, dynamic>?)?['amountToPay']?.toDouble() ?? 0.0;
        double currentReceiverAmount = (receiverSnapshot.data() as Map<String, dynamic>?)?['amountToReceive']?.toDouble() ?? 0.0;

        transaction.update(payerRef, {'amountToPay': currentPayerAmount + amount});
        transaction.update(receiverRef, {'amountToReceive': currentReceiverAmount + amount});
      });
    } catch (e) {
      print("⚠ Error updating balance: $e");
    }
  }

  Future<void> _uploadSplitData(
      List<Map<String, dynamic>> people,
      Map<String, double> finalPayerAmounts,
      List<Map<String, dynamic>> transactions,
      ) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠ User not logged in");
        return;
      }

      // Prepare the paidBy map with UIDs
      Map<String, double> paidBy = {};
      for (var person in people) {
        paidBy[person['uid']] = finalPayerAmounts[person['uid']] ?? 0.0;
      }

      DocumentReference splitRef = await firestore.collection('splits').add({
        'createdBy': user.uid,
        'description': widget.expenseDescription,
        'totalAmount': widget.totalAmount,
        'participants': people.map((p) => p['uid']).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'paidBy': paidBy, // Store paid amounts at split level
        'category': widget.selectedCategory, // Include category
      });

      print("✅ Split created with ID: ${splitRef.id}, PaidBy: $paidBy");

      for (var transaction in transactions) {
        String payerName = transaction['from'];
        String receiverName = transaction['to'];
        double amount = transaction['amount'];

        String payerUid = people.firstWhere((p) => p['name'] == payerName)['uid'];
        String receiverUid = people.firstWhere((p) => p['name'] == receiverName)['uid'];

        await splitRef.collection('transactions').add({
          'from': payerUid,
          'to': receiverUid,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await updateUserBalance(
          payerUid: payerUid,
          receiverUid: receiverUid,
          amount: amount,
        );
      }

      print("✅ All transactions uploaded successfully!");
    } catch (e) {
      print("⚠ Error uploading split data: $e");
    }
  }

  List<Map<String, dynamic>> _calculateTransactions(
      List<Map<String, dynamic>> people,
      double amountPerPerson,
      Map<String, double> finalPayerAmounts,
      ) {
    List<Map<String, dynamic>> transactions = [];
    List<Map<String, dynamic>> balances = people.map((person) {
      return {
        'name': person['name'],
        'balance': (finalPayerAmounts[person['uid']] ?? 0.0) - amountPerPerson,
      };
    }).toList();

    balances.sort((a, b) => (a['balance'] as double).compareTo(b['balance'] as double));

    int i = 0, j = balances.length - 1;
    while (i < j) {
      double owe = -balances[i]['balance'];
      double receive = balances[j]['balance'];
      double amount = owe < receive ? owe : receive;

      if (amount > 0) {
        transactions.add({
          'from': balances[i]['name'],
          'to': balances[j]['name'],
          'amount': amount,
        });
      }

      balances[i]['balance'] += amount;
      balances[j]['balance'] -= amount;

      if (balances[i]['balance'] == 0) i++;
      if (balances[j]['balance'] == 0) j--;
    }

    print("✅ Transactions: $transactions");
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    double amountPerPerson = _calculateAmountPerPerson();
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    User? user = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> allPeople = [
      {"name": "You", "uid": user?.uid ?? ""}
    ]..addAll(widget.selectedPeople);

    Map<String, double> finalPayerAmounts = {};
    for (var person in allPeople) {
      String uid = person['uid'];
      String name = person['name'];
      finalPayerAmounts[uid] = name == "You" && widget.payerAmounts.isEmpty
          ? widget.totalAmount
          : widget.payerAmounts[name] ?? 0.0;
    }

    List<Map<String, dynamic>> transactions = _calculateTransactions(allPeople, amountPerPerson, finalPayerAmounts);

    double userAmount = finalPayerAmounts[user?.uid ?? ""] ?? 0.0;
    double userToPay = amountPerPerson - userAmount;

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.expenseDescription)),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: screenWidth > 600 ? 24 : 22,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: const Color(0xFF1A2E39),
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountBox(
                          screenWidth,
                          "RECEIVE",
                          userToPay < 0 ? -userToPay : 0,
                          Colors.green,
                          Colors.green.shade900,
                        ),
                      ),
                      Expanded(
                        child: _buildAmountBox(
                          screenWidth,
                          "PAY",
                          userToPay > 0 ? userToPay : 0,
                          Colors.redAccent.shade400,
                          Colors.redAccent.shade100,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text("Split Summary",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.teal.shade300, fontWeight: FontWeight.bold, fontSize: screenWidth > 600 ? 32 : 28)),
                  SizedBox(height: screenHeight * 0.02),
                  _buildListView(screenWidth, allPeople, finalPayerAmounts, amountPerPerson),
                  SizedBox(height: screenHeight * 0.03),
                  Text("Transactions to Settle",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.teal.shade300, fontWeight: FontWeight.bold, fontSize: screenWidth > 600 ? 28 : 24)),
                  SizedBox(height: screenHeight * 0.015),
                  _buildListView(screenWidth, transactions, {}, 0),
                  SizedBox(height: screenHeight * 0.025),
                  const Divider(thickness: 1.3, color: Colors.black26),
                  SizedBox(height: screenHeight * 0.02),
                  _buildFinalizeButton(),
                  SizedBox(height: screenHeight * 0.2),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _paymentFinalized,
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [_buildFinalizeButton()],
                  ),
                ),
                if (_paymentFinalized)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Center(
                      child: Lottie.asset('assets/animation/45.json', width: 200, height: 200),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBox(double width, String label, double amount, Color color, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      margin: EdgeInsets.only(bottom: width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 7, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w500, fontSize: width > 600 ? 20 : 18)),
          Padding(
            padding: EdgeInsets.only(top: width * 0.015),
            child: Stack(
              children: [
                Container(
                  height: width * 0.075,
                  decoration: BoxDecoration(color: bgColor.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                ),
                ClipRect(
                  child: Container(
                    height: width * 0.075,
                    width: width * 0.4 * (amount / (label == "RECEIVE" ? 30000 : 10000)),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: width * 0.015, horizontal: width * 0.025),
                  child: Text("₹${amount.toStringAsFixed(0)}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green.shade900, fontWeight: FontWeight.w700, fontSize: width > 600 ? 26 : 22)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(double width, List<Map<String, dynamic>> data,
      Map<String, double> amounts, double amountPerPerson) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: width * 0.0375),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 2, blurRadius: 7, offset: const Offset(0, 5)),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) => _buildListTile(width, data[index], amounts, amountPerPerson),
      ),
    );
  }

  Widget _buildListTile(double width, Map<String, dynamic> item,
      Map<String, double> amounts, double amountPerPerson) {
    if (item.containsKey('name')) { // Split Summary
      String name = item["name"];
      String uid = item["uid"];
      double amountPaid = amounts[uid] ?? 0.0;
      double amountToPay = amountPerPerson - amountPaid;
      String amountText = amountToPay > 0 ? "-₹${amountToPay.toStringAsFixed(0)}" : "+₹${(-amountToPay).toStringAsFixed(0)}";
      TextStyle amountStyle = TextStyle(
        color: amountToPay > 0 ? Colors.redAccent.shade700 : Colors.green.shade700,
        fontWeight: FontWeight.w700,
        fontSize: width > 600 ? 20 : 17,
      );

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.0375, vertical: width * 0.02),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(name == "You" ? LucideIcons.user : LucideIcons.users, color: Colors.teal.shade700, size: width * 0.075),
          ),
          title: Text(name == "You" ? "You" : name,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: width > 600 ? 22 : 18, color: Colors.black87)),
          subtitle: Text("Paid: ₹${amountPaid.toStringAsFixed(2)}",
              style: TextStyle(fontSize: width > 600 ? 18 : 15, color: Colors.grey.shade600)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountText, style: amountStyle),
              Text(amountToPay > 0 ? "To Pay" : "To Receive",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: width > 600 ? 16 : 13)),
            ],
          ),
        ),
      );
    } else { // Transactions to Settle
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.0375, vertical: width * 0.025),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: EdgeInsets.all(width * 0.02),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(LucideIcons.arrowRightCircle, color: Colors.teal.shade700, size: width * 0.065),
          ),
          title: Text("${item['from']} to ${item['to']}",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: width > 600 ? 20 : 17, color: Colors.black87)),
          trailing: Text("₹${item['amount'].toStringAsFixed(2)}",
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: width > 600 ? 20 : 17,
                  color: Colors.green.shade700)),
        ),
      );
    }
  }

  Widget _buildFinalizeButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _handleFinalizePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700, // Button color
          foregroundColor: Colors.white, // Text/icon color
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.1,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: const Text(
          "Finalize Payment",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}