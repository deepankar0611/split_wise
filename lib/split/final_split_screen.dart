import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:slider_button/slider_button.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui'; // Import dart:ui for ImageFilter

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

class _FinalSplitScreenState extends State<FinalSplitScreen> {
  bool _paymentFinalized = false;
  bool _isDarkMode = false;


  double _calculateAmountPerPerson() {
    return widget.totalAmount / (widget.selectedPeople.length + 1);
  }

  void _handleFinalizePayment() {
    setState(() {
      _paymentFinalized = true;
    });
    // Navigator.pop(context); // Removed to keep animation on screen
  }

  // START OF ALGORITHM - _calculateTransactions function
  List<Map<String, dynamic>> _calculateTransactions(List<Map<String, dynamic>> people, double amountPerPerson, Map<String, double> amounts) {
    List<Map<String, dynamic>> transactions = [];
    List<Map<String, dynamic>> balances = people.map((person) {
      return {'name': person['name'], 'balance': (amounts[person['name']] ?? 0.0) - amountPerPerson};
    }).toList();

    balances.sort((a, b) => (a['balance'] as double).compareTo((b['balance'] as double)));

    int i = 0, j = balances.length - 1;
    while (i < j) {
      double owe = -balances[i]['balance'];
      double receive = balances[j]['balance'];

      double amount = owe < receive ? owe : receive;
      transactions.add({'from': balances[i]['name'], 'to': balances[j]['name'], 'amount': amount});

      balances[i]['balance'] += amount;
      balances[j]['balance'] -= amount;

      if (balances[i]['balance'] == 0) i++;
      if (balances[j]['balance'] == 0) j--;
    }

    return transactions;
  }
  // END OF ALGORITHM - _calculateTransactions function


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

    List<Map<String, dynamic>> transactions =
    _calculateTransactions(allPeople, amountPerPerson, finalPayerAmounts);

    // Calculate what 'You' has to pay or receive
    double userAmount = finalPayerAmounts["You"] ?? 0.0;
    double userToPay = amountPerPerson - userAmount;

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF121212) : const Color(
          0xFFF5F5F5),
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
      body: Stack( // Wrapped body with Stack
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
                            userToPay < 0 ? -userToPay : 0, // If user has paid more, they receive the excess
                            Colors.green,
                            Colors.green.shade900),
                      ),
                      Expanded(
                        child: _buildAmountBox(
                            screenWidth,
                            "PAY",
                            userToPay > 0 ? userToPay : 0, // If user owes money, this is the amount to pay
                            Colors.redAccent.shade400,
                            Colors.redAccent.shade100),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text("Split Summary",
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.teal.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth > 600 ? 32 : 28)),
                  SizedBox(height: screenHeight * 0.02),
                  _buildListView(
                      screenWidth, allPeople, finalPayerAmounts, amountPerPerson),
                  SizedBox(height: screenHeight * 0.03),
                  Text("Transactions to Settle",
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.teal.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth > 600 ? 28 : 24)),
                  SizedBox(height: screenHeight * 0.015),
                  _buildListView(screenWidth, transactions, {}, 0),
                  SizedBox(height: screenHeight * 0.025),
                  Divider(thickness: 1.3,
                      color: _isDarkMode ? Colors.grey.shade600 : Colors.black26),
                  SizedBox(height: screenHeight * 0.02),
                  _buildFinalizeButton(),
                  SizedBox(height: screenHeight * 0.2), // Increased SizedBox height
                ],
              ),
            ),
          ),
          Visibility( // Visibility widget for blur and animation
            visible: _paymentFinalized,
            child: Stack(
              children: [
                BackdropFilter( // Blur effect
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                Center( // Centered Lottie animation
                  child: Lottie.asset(
                    'assets/animation/45.json', // Path to your Lottie animation JSON file
                    width: screenWidth * 0.8, // Adjust size as needed, full screen width - some padding
                    height: screenWidth * 0.8, // Adjust size as needed,  full screen width - some padding
                    repeat: false, // Play once
                    reverse: false,
                    animate: true,
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

  Widget _buildListView(double width, List<Map<String, dynamic>> data,
      Map<String, double> amounts, double amountPerPerson) {
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
        itemBuilder: (context, index) =>
            _buildListTile(width, data[index], amounts, amountPerPerson, ),
      ),
    );
  }


  Widget _buildListTile(double width, Map<String, dynamic> item,
      Map<String, double> amounts, double amountPerPerson) {
    if (item.containsKey('name')) { // For Split Summary
      String payer = item["name"];
      double amountPaid = amounts[payer] ?? 0.0;
      double amountToPay = amountPerPerson - amountPaid;
      String amountText;
      TextStyle amountStyle;

      if (amountToPay > 0) {
        amountText = "-₹${amountToPay.toStringAsFixed(0)}";
        amountStyle = TextStyle(color: Colors.redAccent.shade700,
            fontWeight: FontWeight.w700,
            fontSize: width > 600 ? 20 : 17);
      } else {
        amountText = "+₹${(-amountToPay).toStringAsFixed(0)}";
        amountStyle = TextStyle(color: Colors.green.shade700,
            fontWeight: FontWeight.w700,
            fontSize: width > 600 ? 20 : 17);
      }

      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.0375, vertical: width * 0.02),
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
                  color: _isDarkMode ? Colors.grey.shade400 : Colors.grey
                      .shade600)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountText, style: amountStyle),
              Text(
                amountToPay > 0 ? "To Pay" : "To Receive",
                style: TextStyle(
                    color: _isDarkMode ? Colors.grey.shade400 : Colors.grey
                        .shade500,
                    fontSize: width > 600 ? 16 : 13),
              ),
            ],
          ),
        ),
      );
    } else { // For Transactions to Settle
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
            "${item['from']} has to pay ₹${item['amount'].toStringAsFixed(2)} to ${item['to']}",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: width > 600 ? 20 : 17,
                color: _isDarkMode ? Colors.white : Colors.black87
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFinalizeButton() {
    return Center(
      child: SliderButton(
        action: () async {
          _handleFinalizePayment();
          return true;
        },
        label: const Text("Slide to Finalize Payment"),
        buttonColor: Colors.teal.shade400,
      ),
    );
  }

// _buildFinalizedMessage removed, Lottie animation is used instead
}