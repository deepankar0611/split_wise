import 'package:flutter/material.dart';

class PayerSelectionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final List<String> selectedPayers;
  final Map<String, double> payerAmounts;
  final double totalAmount;
  final Function(List<String>, Map<String, double>) onSelectionDone;

  const PayerSelectionSheet({
    super.key,
    required this.friends,
    required this.selectedPayers,
    required this.payerAmounts,
    required this.totalAmount,
    required this.onSelectionDone,
  });

  @override
  _PayerSelectionSheetState createState() => _PayerSelectionSheetState();
}

class _PayerSelectionSheetState extends State<PayerSelectionSheet> {
  late List<String> selectedPayers;
  late Map<String, double> payerAmounts;
  double remainingAmount = 0.0;
  Map<String, String?> errorMessages = {};

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
      appBar: AppBar(
        toolbarHeight: 50, // Increased toolbarHeight for a more prominent AppBar
        backgroundColor: Color(0xFF1A2E39), // Teal AppBar color
        shape: const RoundedRectangleBorder( // Rounded bottom corners for AppBar
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        elevation: 3, // Subtle elevation for AppBar
        shadowColor: Colors.black.withOpacity(0.4), // Shadow color
        title: Text(
          "Choose Payers",
          style: const TextStyle(
            fontSize: 24, // Slightly smaller font in AppBar
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text for AppBar
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true, // Center the title
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Padding( // Added Padding back to the body content
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10), // Spacing below AppBar
              Expanded(
                child: ListView.builder(
                  itemCount: widget.friends.length,
                  itemBuilder: (context, index) {
                    final friend = widget.friends[index];
                    final bool isSelected = selectedPayers.contains(friend["name"]);
                    return Card(
                      elevation: 2,
                      color: Colors.grey[50],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Avatar with Status Indicator
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: friend["profilePic"]?.isNotEmpty == true
                                      ? NetworkImage(friend["profilePic"])
                                      : null,
                                  backgroundColor: Colors.grey.shade300,
                                  child: (friend["profilePic"]?.isEmpty ?? true)
                                      ? Text(
                                    friend["name"][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : null,
                                ),
                                if (isSelected)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Name and Optional Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend["name"],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    payerAmounts[friend["name"]] != null && payerAmounts[friend["name"]]! > 0
                                        ? "Paid: ₹ ${payerAmounts[friend["name"]]!.toStringAsFixed(2)}"
                                        : "Not paid yet",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: payerAmounts[friend["name"]] != null && payerAmounts[friend["name"]]! > 0
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selection Toggle
                            Switch(
                              value: isSelected,
                              activeColor: Colors.teal.shade700,
                              onChanged: (value) {
                                setState(() {
                                  if (value) {
                                    selectedPayers.add(friend["name"]);
                                    payerAmounts[friend["name"]] = 0.0;
                                  } else {
                                    selectedPayers.remove(friend["name"]);
                                    payerAmounts.remove(friend["name"]);
                                  }
                                  _updateRemainingAmount();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedPayers.isNotEmpty) buildAmountEntry(),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 3,
                ),
                onPressed: () {
                  widget.onSelectionDone(selectedPayers, payerAmounts);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Done",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAmountEntry() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, color: Colors.teal.shade800, size: 28),
              const SizedBox(width: 8),
              Text(
                "Enter Paid Amounts",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...selectedPayers.map((payer) {
            final friend = widget.friends.firstWhere(
                  (f) => f["name"] == payer,
              orElse: () => {"profilePic": "", "name": payer},
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: friend["profilePic"].isNotEmpty ? NetworkImage(friend["profilePic"]) : null,
                    backgroundColor: Colors.grey.shade300,
                    child: friend["profilePic"].isEmpty
                        ? Text(payer[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (errorMessages[payer] != null)
                          Text(
                            errorMessages[payer]!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 16, color: Colors.black87), // **Contrast color for input text**
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixText: "₹ ",
                        prefixStyle: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold), // **Contrast color for prefix**
                        hintText: "0.00",
                        hintStyle: TextStyle(color: Colors.grey[500]), // **Slightly darker hint color**
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal.shade700, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          double enteredAmount = double.tryParse(value) ?? 0.0;
                          double previousAmount = payerAmounts[payer] ?? 0.0;
                          double newRemainingAmount = remainingAmount + previousAmount - enteredAmount;
                          if (newRemainingAmount < 0) {
                            errorMessages[payer] = "Limit exceeded";
                          } else {
                            errorMessages[payer] = null;
                          }
                          payerAmounts[payer] = enteredAmount;
                          _updateRemainingAmount();
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: remainingAmount <= 0 ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: remainingAmount <= 0 ? Colors.green.shade300 : Colors.red.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Paid: ₹ ${payerAmounts.values.fold(0.0, (sum, amount) => sum + amount).toStringAsFixed(2)} of ₹ ${widget.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), // **Contrast color for Total Paid**
                ),
                Text(
                  remainingAmount <= 0 ? "₹ 0.00 left" : "₹ ${remainingAmount.toStringAsFixed(2)} left",
                  style: TextStyle(
                    color: remainingAmount <= 0 ? Colors.green.shade900 : Colors.red.shade900, // **Darker contrast color for "left" text**
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}