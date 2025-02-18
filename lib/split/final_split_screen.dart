import 'package:flutter/material.dart';

class FinalSplitScreen extends StatelessWidget {
  final List<Map<String, dynamic>> selectedPeople;
  final Map<String, double> payerAmounts;
  final double totalAmount;


  const FinalSplitScreen({
    super.key,
    required this.selectedPeople,
    required this.payerAmounts,
    required this.totalAmount,

  });

  double _calculateAmountPerPerson() {
    return totalAmount / (selectedPeople.length + 1); // Including "You"
  }

  @override
  Widget build(BuildContext context) {
    double userName = 0.0;
    double amountPerPerson = _calculateAmountPerPerson();

    // If payerAmounts is empty, assume the user has paid the full amount

    Map<String, double> finalPayerAmounts = {};

    if (payerAmounts.isEmpty) {
      finalPayerAmounts["You"] = totalAmount;
    } else {
      finalPayerAmounts = payerAmounts; // Ensure it's a valid Map<String, double>
    }

    // Create a list including the user
    List<Map<String, dynamic>> allPeople = [
      {"name": "You"} // Fixing name to a valid string
    ]..addAll(selectedPeople);
// Then add others

    // Calculate who owes what to whom
    List<Map<String, dynamic>> transactions = _calculateTransactions(
        allPeople, amountPerPerson, finalPayerAmounts);

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
                itemCount: allPeople.length,
                  itemBuilder: (context, index) {
                    String payer = allPeople[index]["name"];
                    double amountPaid = finalPayerAmounts[payer] ?? 0.0;
                    double amountToPay = amountPerPerson - amountPaid;

                    return ListTile(
                      title: Text(payer == "You" ? "You ($payer)" : payer),
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
                  }

              ),
            ),

            // New section for transactions
            const SizedBox(height: 20),
            const Text(
              "Transactions to Settle",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                        "${transactions[index]['from']} owes ${transactions[index]['to']}"),
                    trailing: Text(
                        "₹${transactions[index]['amount'].toStringAsFixed(2)}"),
                  );
                },
              ),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Amount: ₹${totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Each person's share: ₹${amountPerPerson.toStringAsFixed(
                        2)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
        balances[positiveIndex]['balance'] = positiveBalance + negativeBalance;
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
        balances[negativeIndex]['balance'] = negativeBalance + positiveBalance;
        balances[positiveIndex]['balance'] = 0;
        positiveIndex++;
      }
    }

    return transactions;
  }
}