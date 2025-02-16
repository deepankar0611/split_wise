import 'package:flutter/material.dart';

class PayerSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final List<String> selectedPayers;
  final Map<String, double> payerAmounts;
  final double totalAmount;
  final Function(List<String>, Map<String, double>) onSelectionDone;

  const PayerSelectionSheet({
    Key? key,
    required this.friends,
    required this.selectedPayers,
    required this.payerAmounts,
    required this.totalAmount,
    required this.onSelectionDone,
  }) : super(key: key);

  @override
  _PayerSelectionSheetState createState() => _PayerSelectionSheetState();
}

class _PayerSelectionSheetState extends State<PayerSelectionSheet> {
  late List<String> selectedPayers;
  late Map<String, double> payerAmounts;
  double remainingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    selectedPayers = List.from(widget.selectedPayers);
    payerAmounts = Map.from(widget.payerAmounts);
    _updateRemainingAmount();
  }

  void _updateRemainingAmount() {
    double totalPaid = payerAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    setState(() {
      remainingAmount = widget.totalAmount - totalPaid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Choose Payer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.friends.length,
                    itemBuilder: (context, index) {
                      final friend = widget.friends[index];
                      final bool isSelected = selectedPayers.contains(friend["name"]);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: friend["profilePic"]?.isNotEmpty == true
                              ? NetworkImage(friend["profilePic"])
                              : null,
                          backgroundColor: Colors.grey,
                          child: (friend["profilePic"]?.isEmpty ?? true) ? Text(friend["name"][0]) : null,
                        ),
                        title: Text(friend["name"]),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              selectedPayers.remove(friend["name"]);
                              payerAmounts.remove(friend["name"]);
                            } else {
                              selectedPayers.add(friend["name"]);
                              payerAmounts[friend["name"]] = 0.0;
                            }
                            _updateRemainingAmount();
                          });
                        },
                      );
                    },
                  ),
                ),
                if (selectedPayers.length > 1) const Divider(),
                if (selectedPayers.length > 1) buildAmountEntry(setModalState),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    widget.onSelectionDone(selectedPayers, payerAmounts);
                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildAmountEntry(StateSetter setModalState) {
    return Column(
      children: [
        const Text("Enter Paid Amounts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...selectedPayers.map((payer) {
          final friend = widget.friends.firstWhere(
                (f) => f["name"] == payer,
            orElse: () => {"profilePic": "", "name": payer}, // Avoids crash if payer not found
          );

          return Material(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: friend["profilePic"].isNotEmpty ? NetworkImage(friend["profilePic"]) : null,
                backgroundColor: Colors.grey,
                child: friend["profilePic"].isEmpty ? Text(payer[0]) : null,
              ),
              title: Text(payer),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(prefixText: "₹ "),
                  onChanged: (value) {
                    setModalState(() {
                      // Prevents "Bad state: No element" error
                      if (!payerAmounts.containsKey(payer)) {
                        payerAmounts[payer] = 0.0;
                      }
                      payerAmounts[payer] = double.tryParse(value) ?? 0.0;
                      _updateRemainingAmount();
                    });
                  },
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 10),
        Text(
          "₹ ${widget.totalAmount - remainingAmount} of ₹ ${widget.totalAmount}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          remainingAmount == 0 ? "₹ 0.00 left" : "₹ $remainingAmount left",
          style: TextStyle(color: remainingAmount == 0 ? Colors.green : Colors.red),
        ),
      ],
    );
  }
}
