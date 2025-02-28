import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:slider_button/slider_button.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class FinalSplitScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPeople;
  final Map<String, double> payerAmounts;
  final double totalAmount;
  final String expenseDescription;
  final String selectedCategory;

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
  double _totalAmountToPay = 0.0;
  double _totalAmountToReceive = 0.0;
  String? _currentUserProfilePic;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserProfilePic();
    _calculateTotalAmounts();
  }

  Future<void> _fetchCurrentUserProfilePic() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          setState(() {
            _currentUserProfilePic = (data['profileImageUrl'] as String?)?.isNotEmpty == true ? data['profileImageUrl'] : "";
          });
        }
      }
    } catch (e) {
      print("Error fetching current user's profile picture: $e");
      if (mounted) {
        setState(() {
          _currentUserProfilePic = ""; // Fallback to empty string on error
        });
      }
    }
  }

  void _calculateTotalAmounts() {
    double amountPerPerson = _calculateAmountPerPerson();
    User? user = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> allPeople = [
      {"name": "You", "uid": user?.uid ?? "", "profilePic": _currentUserProfilePic ?? widget.selectedPeople.firstWhere((p) => p['uid'] == user?.uid, orElse: () => {'profilePic': ''})['profilePic']}
    ]..addAll(widget.selectedPeople.where((p) => p['uid'] != user?.uid).toList());

    Map<String, double> finalPayerAmounts = {};
    for (var person in allPeople) {
      String uid = person['uid'];
      String name = person['name'];
      finalPayerAmounts[uid] = name == "You" && widget.payerAmounts.isEmpty
          ? widget.totalAmount
          : widget.payerAmounts[name] ?? 0.0;
    }

    double userAmount = finalPayerAmounts[user?.uid ?? ""] ?? 0.0;
    double userToPay = amountPerPerson - userAmount;

    _totalAmountToPay = userToPay > 0 ? userToPay : 0;
    _totalAmountToReceive = userToPay < 0 ? -userToPay : 0;
  }

  double _calculateAmountPerPerson() {
    return widget.totalAmount / (widget.selectedPeople.length + 1); // +1 for "You"
  }

  void _handleFinalizePayment() {
    setState(() {
      _paymentFinalized = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> people = [
      {"name": "You", "uid": user.uid, "profilePic": _currentUserProfilePic ?? widget.selectedPeople.firstWhere((p) => p['uid'] == user.uid, orElse: () => {'profilePic': ''})['profilePic']}
    ]..addAll(widget.selectedPeople.where((p) => p['uid'] != user.uid).toList());

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

    _uploadSplitData(people, finalPayerAmounts, transactions);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
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
        'paidBy': paidBy,
        'category': widget.selectedCategory,
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
      {"name": "You", "uid": user?.uid ?? "", "profilePic": _currentUserProfilePic ?? widget.selectedPeople.firstWhere((p) => p['uid'] == user?.uid, orElse: () => {'profilePic': ''})['profilePic']}
    ]..addAll(widget.selectedPeople.where((p) => p['uid'] != user?.uid).toList());

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
    _totalAmountToPay = userToPay > 0 ? userToPay : 0;
    _totalAmountToReceive = userToPay < 0 ? -userToPay : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: screenHeight * 0.25,
                backgroundColor: const Color(0xFF234567),
                centerTitle: true,
                title: Text(
                  widget.expenseDescription.isNotEmpty ? widget.expenseDescription : "Split Details",
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
                        (screenHeight * 0.25 - constraints.biggest.height) / (screenHeight * 0.25 - kToolbarHeight);
                    final cardAnimationProgress = collapseProgress.clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      background: Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.005),
                          child: Transform.translate(
                            offset: Offset(0, cardAnimationProgress * screenHeight * 0.05),
                            child: Transform.scale(
                              scale: 1.0 - cardAnimationProgress * 0.1,
                              child: _buildTotalSpendReceiveCard(_totalAmountToPay, _totalAmountToReceive, context),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.01),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Split Summary",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Color(0xFF234567),
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth > 600 ? 22 : 21),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      _buildListView(screenWidth, allPeople, finalPayerAmounts, amountPerPerson),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Transactions to Settle",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Color(0xFF234567),
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth > 600 ? 22 : 21),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      _buildListView(screenWidth, transactions, {}, 0),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            bottom: screenHeight * 0.03,
            child: _buildFinalizeButton(),
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
    );
  }

  Widget _buildListView(double width, List<Map<String, dynamic>> data, Map<String, double> amounts, double amountPerPerson) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: width * 0.01),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2)),
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

  Widget _buildListTile(double width, Map<String, dynamic> item, Map<String, double> amounts, double amountPerPerson) {
    TextStyle bodyTextStyle = TextStyle(fontSize: width > 600 ? 14 : 12);

    if (item.containsKey('name')) {
      String name = item["name"];
      String uid = item["uid"];
      String? profilePic = item["profilePic"];
      double amountPaid = amounts[uid] ?? 0.0;
      double amountToPay = amountPerPerson - amountPaid;
      String amountText = amountToPay > 0 ? "-₹${amountToPay.toStringAsFixed(0)}" : "+₹${(-amountToPay).toStringAsFixed(0)}";
      TextStyle amountStyle = TextStyle(
        color: amountToPay > 0 ? Colors.redAccent.shade700 : Colors.green.shade700,
        fontWeight: FontWeight.w700,
        fontSize: width > 600 ? 18 : 15,
      );

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: width * 0.005),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: width * 0.1,
            height: width * 0.1,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.teal.shade50,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: profilePic != null && profilePic.isNotEmpty
                  ? Image.network(
                profilePic,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    name == "You" ? LucideIcons.user : LucideIcons.users,
                    color: Colors.teal.shade700,
                    size: width * 0.05,
                  );
                },
              )
                  : Icon(
                name == "You" ? LucideIcons.user : LucideIcons.users,
                color: Colors.teal.shade700,
                size: width * 0.05,
              ),
            ),
          ),
          title: Text(
            name,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: width > 600 ? 16 : 14, color: Colors.black87),
          ),
          subtitle: Text(
            "Paid: ₹${amountPaid.toStringAsFixed(2)}",
            style: bodyTextStyle.copyWith(color: Colors.grey.shade600),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountText, style: amountStyle),
              Text(
                amountToPay > 0 ? "To Pay" : "To Receive",
                style: bodyTextStyle.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: width * 0.005),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(LucideIcons.arrowRightCircle, color: Colors.teal.shade700, size: width * 0.05),
          ),
          title: Text(
            "${item['from']} to ${item['to']}",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: width > 600 ? 16 : 14, color: Colors.black87),
          ),
          trailing: Text(
            "₹${item['amount'].toStringAsFixed(2)}",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: width > 600 ? 16 : 14, color: Colors.green.shade700),
          ),
        ),
      );
    }
  }

  Widget _buildFinalizeButton() {
    return SliderButton(
      action: () async {
        _handleFinalizePayment();
        return true;
      },
      label: const Text("Slide to Finalize Payment"),
      backgroundColor: Colors.grey.shade200,
      buttonColor: Color(0xFF234567),
      icon: const Center(
        child: Text(
          ">",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      width: MediaQuery.of(context).size.width * 0.9,
    );
  }

  Widget _buildTotalSpendReceiveCard(double totalSpent, double totalReceived, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.015),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pay',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: (screenSize.width * 0.03).clamp(8, 12),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.arrowDown,
                          color: Colors.redAccent.shade200, size: (screenSize.width * 0.035).clamp(10, 14)),
                      SizedBox(width: screenSize.width * 0.005),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: (screenSize.width * 0.04).clamp(12, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: screenSize.height * 0.025,
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.005),
              child: VerticalDivider(
                color: Colors.black,
                thickness: 1,
              ),
            ),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Receive',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: (screenSize.width * 0.03).clamp(8, 12),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.arrowUp,
                          color: Colors.greenAccent.shade200, size: (screenSize.width * 0.035).clamp(10, 14)),
                      SizedBox(width: screenSize.width * 0.005),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${totalReceived.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: (screenSize.width * 0.04).clamp(12, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}