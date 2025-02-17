import 'package:flutter/material.dart';
import 'package:slider_button/slider_button.dart';

class FinalSplitScreen extends StatefulWidget {
  const FinalSplitScreen({super.key});

  @override
  State<FinalSplitScreen> createState() => _FinalSplitScreenState();
}

class _FinalSplitScreenState extends State<FinalSplitScreen> {
  final List<Map<String, dynamic>> friends = [
    {"name": "Lily Black", "amount": 2570, "isPositive": true},
    {"name": "Shawn Mckinney", "amount": 625, "isPositive": true},
    {"name": "Stella Cooper", "amount": 1180, "isPositive": false},
    {"name": "Dwight Jones", "amount": 700, "isPositive": true},
    {"name": "Eduardo Bell", "amount": 935, "isPositive": false},
    {"name": "Philip Steward", "amount": 1460, "isPositive": true},
    {"name": "Jenny Miles", "amount": 1257, "isPositive": true},
    {"name": "Jacob Richards", "amount": 2935, "isPositive": false},
  ];

  double get totalReceive => friends.where((f) => f['isPositive']).fold(0.0, (sum, f) => sum + f['amount']);
  double get totalPay => friends.where((f) => !f['isPositive']).fold(0.0, (sum, f) => sum + f['amount']);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friends"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceCard("RECEIVE", "₹ ${totalReceive.toStringAsFixed(2)}", Colors.green),
                _buildBalanceCard("PAY", "₹ ${totalPay.toStringAsFixed(2)}", Colors.red),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Text(friend['name'][0]),
                  ),
                  title: Text(friend['name']),
                  trailing: Text(
                    "${friend['isPositive'] ? '+' : '-'} ₹${friend['amount']}",
                    style: TextStyle(
                      color: friend['isPositive'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SliderButton(
                action: () async {
                  /// Do something here OnSlide
                  return true;
                },
                label: Text(
                  "Slide to SettleUp",
                  style: TextStyle(
                    color: Color(0xff4a4a4a),
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
                ),
                icon: Text(
                  "x",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 44,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, String amount, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5.0),
            Text(
              amount,
              style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
