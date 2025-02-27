import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? currentUserProfilePic;
  Map<String, TextEditingController> amountControllers = {};

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    selectedPayers = List.from(widget.selectedPayers);
    payerAmounts = Map.from(widget.payerAmounts);
    _updateRemainingAmount();
    _fetchCurrentUserProfilePic();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize for "You" explicitly
    amountControllers["You"] = TextEditingController(
      text: (payerAmounts["You"] ?? 0.0) > 0 ? payerAmounts["You"]!.toStringAsFixed(2) : "",
    );
    // Initialize for other friends
    for (var friend in widget.friends) {
      String name = friend["name"];
      amountControllers[name] = TextEditingController(
        text: (payerAmounts[name] ?? 0.0) > 0 ? payerAmounts[name]!.toStringAsFixed(2) : "",
      );
    }
  }

  Future<void> _fetchCurrentUserProfilePic() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          currentUserProfilePic = data['profileImageUrl'] as String? ?? "";
        });
      } else if (mounted) {
        setState(() {
          currentUserProfilePic = "";
        });
      }
    } catch (e) {
      print("Error fetching current user's profile picture: $e");
      if (mounted) {
        setState(() {
          currentUserProfilePic = "";
        });
      }
    }
  }

  void _updateRemainingAmount() {
    double totalPaid = payerAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    setState(() {
      remainingAmount = widget.totalAmount - totalPaid;
    });
  }

  @override
  void dispose() {
    amountControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.06),
        child: AppBar(
          backgroundColor: const Color(0xFF1A2E39),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(screenWidth * 0.06),
              bottomRight: Radius.circular(screenWidth * 0.06),
            ),
          ),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.4),
          title: Text(
            "Choose Payers",
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenHeight * 0.015),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.friends.length,
                itemBuilder: (context, index) {
                  final friend = widget.friends[index];
                  final bool isSelected = selectedPayers.contains(friend["name"]);
                  return Card(
                    elevation: screenWidth * 0.005,
                    color: Colors.grey[50],
                    margin: EdgeInsets.symmetric(vertical: screenHeight * 0.007),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: screenWidth * 0.06,
                                backgroundImage: friend["name"] == "You" && currentUserProfilePic != null && currentUserProfilePic!.isNotEmpty
                                    ? NetworkImage(currentUserProfilePic!)
                                    : friend["profilePic"]?.isNotEmpty == true
                                    ? NetworkImage(friend["profilePic"])
                                    : null,
                                backgroundColor: Colors.grey.shade300,
                                child: friend["name"] == "You" && (currentUserProfilePic == null || currentUserProfilePic!.isEmpty)
                                    ? Text(
                                  "Y",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : friend["profilePic"]?.isEmpty == true
                                    ? Text(
                                  friend["name"][0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.05,
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
                                    padding: EdgeInsets.all(screenWidth * 0.005),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: screenWidth * 0.04,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend["name"],
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.002),
                                Text(
                                  payerAmounts[friend["name"]] != null && payerAmounts[friend["name"]]! > 0
                                      ? "Paid: ₹ ${payerAmounts[friend["name"]]!.toStringAsFixed(2)}"
                                      : "Not paid yet",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: payerAmounts[friend["name"]] != null && payerAmounts[friend["name"]]! > 0
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isSelected,
                            activeColor: Colors.teal.shade700,
                            onChanged: (value) {
                              setState(() {
                                if (value) {
                                  selectedPayers.add(friend["name"]);
                                  payerAmounts[friend["name"]] = payerAmounts[friend["name"]] ?? 0.0;
                                } else {
                                  selectedPayers.remove(friend["name"]);
                                  payerAmounts.remove(friend["name"]);
                                  amountControllers[friend["name"]]!.clear();
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
              if (selectedPayers.isNotEmpty) buildAmountEntry(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.025),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.02,
                  ),
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.075)),
                  elevation: screenWidth * 0.007,
                ),
                onPressed: () {
                  widget.onSelectionDone(selectedPayers, payerAmounts);
                  Navigator.pop(context);
                },
                child: Text(
                  "Done",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAmountEntry(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenWidth * 0.012),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, color: Colors.teal.shade800, size: screenWidth * 0.07),
              SizedBox(width: screenWidth * 0.02),
              Text(
                "Enter Paid Amounts",
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          ...selectedPayers.map((payer) {
            final friend = widget.friends.firstWhere(
                  (f) => f["name"] == payer,
              orElse: () => {"profilePic": "", "name": payer},
            );
            return Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.055,
                    backgroundImage: payer == "You" && currentUserProfilePic != null && currentUserProfilePic!.isNotEmpty
                        ? NetworkImage(currentUserProfilePic!)
                        : friend["profilePic"].isNotEmpty
                        ? NetworkImage(friend["profilePic"])
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: payer == "You" && (currentUserProfilePic == null || currentUserProfilePic!.isEmpty)
                        ? Text(
                      "Y",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                      ),
                    )
                        : friend["profilePic"].isEmpty
                        ? Text(
                      payer[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                      ),
                    )
                        : null,
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payer,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                        if (errorMessages[payer] != null)
                          Text(
                            errorMessages[payer]!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: screenWidth * 0.03,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  SizedBox(
                    width: screenWidth * 0.25,
                    child: TextField(
                      controller: amountControllers[payer],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixText: "₹ ",
                        prefixStyle: TextStyle(
                          color: Colors.teal.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04,
                        ),
                        hintText: "0.00",
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: screenWidth * 0.04,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.teal.shade700, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.017,
                          horizontal: screenWidth * 0.035,
                        ),
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
          SizedBox(height: screenHeight * 0.025),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.008,
              vertical: screenHeight * 0.022,
            ),
            decoration: BoxDecoration(
              color: remainingAmount <= 0 ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: remainingAmount <= 0 ? Colors.green.shade300 : Colors.red.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Paid: ₹ ${payerAmounts.values.fold(0.0, (sum, amount) => sum + amount).toStringAsFixed(2)} of ₹ ${widget.totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  remainingAmount <= 0 ? "₹ 0.00 left" : "₹ ${remainingAmount.toStringAsFixed(2)} left",
                  style: TextStyle(
                    color: remainingAmount <= 0 ? Colors.green.shade900 : Colors.red.shade900,
                    fontSize: screenWidth * 0.04,
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