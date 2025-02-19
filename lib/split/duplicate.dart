import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:slider_button/slider_button.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import 'dart:convert'; // Import for JSON decoding (if you still need it for other config)
import 'package:flutter/services.dart'; // Import for asset loading
import 'package:lottie/lottie.dart'; // Import the lottie package


class FinalSplitScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPeople;
  final Map<String, double> payerAmounts;
  final double totalAmount;

  const FinalSplitScreen({
    super.key,
    required this.selectedPeople,
    required this.payerAmounts,
    required this.totalAmount,
  });

  @override
  State<FinalSplitScreen> createState() => _FinalSplitScreenState();
}

class _FinalSplitScreenState extends State<FinalSplitScreen> with SingleTickerProviderStateMixin {
  bool _paymentFinalized = false;
  bool _isDarkMode = false;
  String _buttonText = "Slide to Finalize Payment";
  late AnimationController _animationController;
  late Animation<double> _animation;
  // List<dynamic> _animationConfig = []; // No longer needed for Lottie approach

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutQuart
    ));
    // _loadAnimationConfig(); // No longer needed for Lottie approach
  }

  // Future<void> _loadAnimationConfig() async { // No longer needed for Lottie approach
  //   final String response = await rootBundle.loadString('assets/animation/45.json'); // Path to your JSON file
  //   final data = await json.decode(response);
  //   setState(() {
  //     _animationConfig = data;
  //   });
  // }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _calculateAmountPerPerson() {
    return widget.totalAmount / (widget.selectedPeople.length + 1);
  }

  void _handleFinalizePayment() {
    setState(() {
      _paymentFinalized = true;
      _buttonText = "Payment Finalized!";
    });
    _animationController.forward(); // Start animation on payment finalization
    // No navigation to another page anymore
  }

  @override
  Widget build(BuildContext context) {
    double amountPerPerson = _calculateAmountPerPerson();
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    Map<String, double> finalPayerAmounts = widget.payerAmounts.isEmpty
        ? {"You": widget.totalAmount}
        : Map.from(widget.payerAmounts);

    List<Map<String, dynamic>> allPeople = [
      {"name": "You"}
    ]..addAll(widget.selectedPeople);

    // Calculate who owes what to whom
    List<Map<String, dynamic>> transactions = _calculateTransactions(
        allPeople, amountPerPerson, finalPayerAmounts);

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF3C7986) : const Color(0xFF1A2E39),
      appBar: AppBar(
        title: const Text("Split Details"),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: screenWidth > 600 ? 24 : 22,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: const Color(0xFF1A2E39),
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            child: CupertinoSwitch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
              activeColor: Colors.teal.shade400,
            ),
          ),
        ],
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
                        child: _buildAmountBox(screenWidth, "RECEIVE", widget.totalAmount, Colors.green.shade400, Colors.green.shade100),
                      ),
                      Expanded(
                        child: _buildAmountBox(screenWidth, "PAY", amountPerPerson, Colors.redAccent.shade400, Colors.redAccent.shade100),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text("Split Summary",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.teal.shade300, fontWeight: FontWeight.bold, fontSize: screenWidth > 600 ? 32 : 28)),
                  SizedBox(height: screenHeight * 0.02),
                  _buildListView(screenWidth, allPeople, finalPayerAmounts, amountPerPerson),
                  SizedBox(height: screenHeight * 0.03),
                  Text("Transactions to Settle",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.teal.shade300, fontWeight: FontWeight.bold, fontSize: screenWidth > 600 ? 28 : 24)),
                  SizedBox(height: screenHeight * 0.015),
                  _buildListView(screenWidth, transactions, {}, 0),
                  SizedBox(height: screenHeight * 0.025),
                  Divider(thickness: 1.3, color: _isDarkMode ? Colors.grey.shade600 : Colors.black26),
                  SizedBox(height: screenHeight * 0.02),
                  _buildFinalizeButton(),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
          if (_paymentFinalized) // Conditionally show the animation
            _buildFinalizationAnimation()
        ],
      ),
    );
  }

  Widget _buildAmountBox(double width, String label, double amount, Color color, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      margin: EdgeInsets.only(bottom: width * 0.04),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w500, fontSize: width > 600 ? 20 : 18)),
          Padding(
            padding: EdgeInsets.only(top: width * 0.015),
            child: Stack(
              children: [
                Container(
                  height: width * 0.075,
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                ClipRect(
                  child: Container(
                    height: width * 0.075,
                    width: width * 0.4 * (amount / (label == "RECEIVE" ? 30000 : 10000)),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: width * 0.015, horizontal: width * 0.025),
                  child: Text("₹${amount.toStringAsFixed(0)}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: width > 600 ? 26 : 22)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(double width, List<Map<String, dynamic>> data, Map<String, double> amounts, double amountPerPerson) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: width * 0.0375),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 5),
          ),
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
    if (item.containsKey('name')) {  // For Split Summary
      String payer = item["name"];
      double amountPaid = amounts[payer] ?? 0.0;
      double amountToPay = amountPerPerson - amountPaid;
      String amountText;
      TextStyle amountStyle;

      if (amountToPay > 0) {
        amountText = "-₹${amountToPay.toStringAsFixed(0)}";
        amountStyle = TextStyle(color: Colors.redAccent.shade700, fontWeight: FontWeight.w700, fontSize: width > 600 ? 20 : 17);
      } else {
        amountText = "+₹${(-amountToPay).toStringAsFixed(0)}";
        amountStyle = TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: width > 600 ? 20 : 17);
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.0375, vertical: width * 0.02),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              payer == "You" ? LucideIcons.user : LucideIcons.users,
              color: Colors.teal.shade700,
              size: width * 0.075,
            ),
          ),
          title: Text(payer == "You" ? "You" : payer,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: width > 600 ? 22 : 18,
                  color: _isDarkMode ? Colors.white : Colors.black87)),
          subtitle: Text("Paid: ₹${amountPaid.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: width > 600 ? 18 : 15,
                  color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountText, style: amountStyle),
              Text(
                amountToPay > 0 ? "To Pay" : "To Receive",
                style: TextStyle(
                    color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: width > 600 ? 16 : 13),
              ),
            ],
          ),
        ),
      );
    } else {  // For Transactions to Settle
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.0375, vertical: width * 0.025),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: EdgeInsets.all(width * 0.02),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.arrowRightCircle, color: Colors.teal.shade700, size: width * 0.065),
          ),
          title: Text(
              "${item['from']}  to  ${item['to']}",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: width > 600 ? 20 : 17,
                  color: _isDarkMode ? Colors.white : Colors.black87)),
          trailing: Text("₹${item['amount'].toStringAsFixed(2)}",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width > 600 ? 20 : 17,
                  color: _isDarkMode ? Colors.white : Colors.black87)),
        ),
      );
    }
  }

  Widget _buildFinalizeButton() {
    var screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.0625),
      child: Shimmer.fromColors(
        baseColor: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        highlightColor: _isDarkMode ? Colors.grey.shade500 : Colors.grey.shade100,
        enabled: !_paymentFinalized,
        child: SliderButton(
          backgroundColor: const Color(0xFF37474F),
          action: () async {
            ///Do something here OnSlide
            _handleFinalizePayment();
            return true;
          },
          label: Text(
            _buttonText,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: screenWidth > 600 ? 22 : 19),
          ),
          icon: Icon(
            LucideIcons.chevronRight,
            color: Colors.black,
            size: screenWidth * 0.075,
          ),
          buttonColor: Colors.teal.shade400,
          shimmer: true,
          highlightedColor: Colors.white30,
          baseColor: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildFinalizationAnimation() {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        color: _isDarkMode ? const Color(0xFF3C7986).withOpacity(0.95) : const Color(0xFF1A2E39).withOpacity(0.95),
        width: screenWidth,
        height: screenHeight,
        child: Center(
          child: Lottie.asset( // Use Lottie.asset to load the animation
            'assets/animation/45.json', // Path to your Lottie file
            width: screenWidth * 0.8, // Adjust size as needed
            height: screenWidth * 0.8,
            controller: _animationController, // Connect to the animation controller
            onLoaded: (composition) {
              // Optional: Control animation properties if needed after loading
              _animationController.duration = composition.duration;
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateTransactions(
      List<Map<String, dynamic>> allPeople,
      double amountPerPerson,
      Map<String, double> finalPayerAmounts) {
    List<Map<String, dynamic>> transactions = [];

    // Sort by how much each person owes (or is owed)
    List<Map<String, dynamic>> balances = allPeople.map((person) {
      double balance = (finalPayerAmounts[person['name']] ?? 0.0) -
          amountPerPerson;
      return {'name': person['name'], 'balance': balance};
    }).toList();

    balances.sort((a, b) =>
        (a['balance'] as double).compareTo(b['balance'] as double));

    // Match people with negative balance (owes money) to those with positive balance (gets money)
    int positiveIndex = 0,
        negativeIndex = balances.length - 1;
    while (positiveIndex < negativeIndex) {
      double positiveBalance = balances[positiveIndex]['balance'] as double;
      double negativeBalance = balances[negativeIndex]['balance'] as double;

      if (positiveBalance > -negativeBalance) {
        transactions.add({
          'from': balances[negativeIndex]['name'],
          'to': balances[positiveIndex]['name'],
          'amount': -negativeBalance,
        });
        balances[positiveIndex]['balance'] += positiveBalance + negativeBalance;
        balances[negativeIndex]['balance'] = 0;
        negativeIndex--;
      } else if (positiveBalance == -negativeBalance) {
        transactions.add({
          'from': balances[negativeIndex]['name'],
          'to': balances[positiveIndex]['name'],
          'amount': positiveBalance,
        });
        balances[positiveIndex]['balance'] = 0;
        balances[negativeIndex]['balance'] = 0;
        positiveIndex++;
        negativeIndex--;
      } else {
        transactions.add({
          'from': balances[negativeIndex]['name'],
          'to': balances[positiveIndex]['name'],
          'amount': positiveBalance,
        });
        balances[negativeIndex]['balance'] += negativeBalance + positiveBalance;
        balances[positiveIndex]['balance'] = 0;
        positiveIndex++;
      }
    }

    return transactions;
  }
}