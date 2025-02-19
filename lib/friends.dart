import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:split_wise/split/final_split_screen.dart';
import 'payer_selection_sheet.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.payerAmounts});
  final Map<String, double> payerAmounts;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> displayFriends = [];
  List<Map<String, dynamic>> selectedPeople = [];
  String searchQuery = "";
  bool showExpenseDetails = false;
  String selectedCategory = "Grocery";
  List<String> selectedPayers = ["You"];
  Map<String, double> payerAmounts = {};
  double totalAmount = 0.0;
  String expenseDescription = "";

  final List<String> categories = [
    "Grocery", "Medicine", "Food", "Rent", "Travel",
    "Shopping", "Entertainment", "Utilities", "Others"
  ];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();
    setState(() {
      friends = snapshot.docs.map((doc) {
        return {
          "uid": doc.id,
          "name": doc["name"] ?? "Unknown",
          "profilePic": doc["profilePic"] ?? "",
        };
      }).toList();
      displayFriends = List.from(friends);
    });
  }

  void _toggleSelection(Map<String, dynamic> friend) {
    setState(() {
      bool isSelected = selectedPeople.any((p) => p['uid'] == friend['uid']);
      if (isSelected) {
        selectedPeople.removeWhere((p) => p['uid'] == friend['uid']);
      } else {
        selectedPeople.add(friend);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Add an Expense",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF234567),
        elevation: 4,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (totalAmount != 0 && expenseDescription.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinalSplitScreen(
                      selectedPeople: selectedPeople,
                      payerAmounts: payerAmounts,
                      totalAmount: totalAmount,
                      expenseDescription: expenseDescription,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount and Description.')),
                );
              }
            },
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("With you and:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8.0,
                    children: selectedPeople.map((friend) {
                      return Chip(
                        label: Text(friend['name']),
                        avatar: CircleAvatar(
                          backgroundImage: friend['profilePic'].isNotEmpty
                              ? NetworkImage(friend['profilePic'])
                              : null,
                          backgroundColor: Colors.grey,
                          child: friend['profilePic'].isEmpty
                              ? Text(friend['name'][0])
                              : null,
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _toggleSelection(friend),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search friends...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: displayFriends
                    .where((friend) => friend["name"].toLowerCase().contains(searchQuery))
                    .map((friend) => _buildFriendItem(friend))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF234567),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  shadowColor: Colors.black.withOpacity(0.3),
                  side: BorderSide(color: Colors.white, width: 2),
                  minimumSize: Size(150, 60),
                ),
                onPressed: () {
                  if (selectedPeople.isNotEmpty) {
                    setState(() {
                      showExpenseDetails = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one person.')),
                    );
                  }
                },
                child: const Text(
                  "Next",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: _buildExpenseDetailsUI(),
              crossFadeState: showExpenseDetails ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    bool isSelected = selectedPeople.any((p) => p['uid'] == friend["uid"]);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend["profilePic"].isNotEmpty
            ? NetworkImage(friend["profilePic"])
            : null,
        backgroundColor: Colors.grey,
        child: friend["profilePic"].isEmpty ? Text(friend["name"][0]) : null,
      ),
      title: Text(friend["name"]),
      onTap: () => _toggleSelection(friend),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.teal)
          : null,
    );
  }

  Widget _buildExpenseDetailsUI() {
    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Wrap(
                spacing: 8.0,
                children: selectedPeople.map((friend) {
                  return Chip(
                    label: Text(friend["name"]),
                    avatar: CircleAvatar(
                      backgroundImage: friend["profilePic"].isNotEmpty
                          ? NetworkImage(friend["profilePic"])
                          : null,
                      backgroundColor: Colors.grey,
                      child: friend["profilePic"].isEmpty
                          ? Text(friend["name"][0])
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "₹ 0.00",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    totalAmount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "Add a description",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.description),
                ),
                onChanged: (value) {
                  setState(() {
                    expenseDescription = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Multiple User Payment: ",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayerSelectionSheet(
                            friends: selectedPeople,
                            selectedPayers: selectedPayers,
                            payerAmounts: payerAmounts,
                            totalAmount: totalAmount,
                            onSelectionDone: (updatedPayers, updatedAmounts) {
                              setState(() {
                                selectedPayers = updatedPayers;
                                payerAmounts = updatedAmounts;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Text(selectedPayers.join(", ")),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}