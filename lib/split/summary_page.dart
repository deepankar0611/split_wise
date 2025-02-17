import 'package:flutter/material.dart';



class SummaryPage extends StatelessWidget {
  final Map<String, double> payerAmounts;

  const SummaryPage({super.key, required this.payerAmounts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: payerAmounts.entries.map((entry) {
            return ListTile(
              title: Text(entry.key), // payer name
              subtitle: Text("Amount: ₹ ${entry.value}"),
            );
          }).toList(),
        ),
      ),
    );
  }
}
