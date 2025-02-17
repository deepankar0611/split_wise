import 'package:flutter/material.dart';

class FinalSplitScreen extends StatelessWidget {
  final List<String> selectedPayers;
  final Map<String, double> payerAmounts;
  final double totalAmount;
  final int totalSelectedPeople;

  const FinalSplitScreen({
    super.key,
    required this.selectedPayers,
    required this.payerAmounts,
    required this.totalAmount,
    required this.totalSelectedPeople,
    required Null
    Function(dynamic updatedPayers, dynamic updatedAmounts) onSelectionDone,
  });

  double _calculateAmountPerPerson() {
    return totalAmount / (totalSelectedPeople + 1);
  }

  @override
  Widget build(BuildContext context) {
    double amountPerPerson = _calculateAmountPerPerson();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Final Split Details"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Split Summary",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: selectedPayers.length,
                itemBuilder: (context, index) {
                  String payer = selectedPayers[index];
                  double amountPaid = payerAmounts[payer] ?? 0.0;
                  double amountToPay = amountPerPerson - amountPaid;

                  return ListTile(
                    title: Text(payer),
                    subtitle: Text("Paid: ₹${amountPaid.toStringAsFixed(2)}"),
                    trailing: Text(
                      amountToPay > 0
                          ? "Owes ₹${amountToPay.toStringAsFixed(2)}"
                          : "Receives ₹${(-amountToPay).toStringAsFixed(2)}",
                      style: TextStyle(
                        color: amountToPay > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  );
                },
              ),
            ),

            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Amount: ₹${totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Each person's share: ₹${amountPerPerson.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Finalize",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
