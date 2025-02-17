import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payer_selection_sheet.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> selectedPeople = [];
  String searchQuery = "";
  bool showExpenseDetails = false;

  String selectedCategory = "Grocery";
  List<String> selectedPayers = ["You"];
  Map<String, double> payerAmounts = {};
  double totalAmount = 0.0;

  final List<String> categories = [
    "Grocery", "Medicine", "Food", "Rent", "Travel",
    "Shopping", "Entertainment", "Utilities", "Others"
  ];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  void _fetchFriends() async {
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
        title: const Text("Add an expense"),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: () {}, // TODO: Implement Save logic
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(  // Wrap the entire body in a SingleChildScrollView
        child: Column(
          children: [
            // Search and Selected Friends Section
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
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search friends...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Friends List from Firebase
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('friends')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                friends = snapshot.data!.docs.map((doc) {
                  return {
                    "uid": doc.id,
                    "name": doc["name"] ?? "Unknown",
                    "profilePic": doc["profilePic"] ?? "",
                  };
                }).toList();

                return ListView(
                  shrinkWrap: true, // Added shrinkWrap to prevent overflow
                  children: friends
                      .where((friend) =>
                      friend["name"].toLowerCase().contains(searchQuery))
                      .map((friend) => _buildFriendItem(friend))
                      .toList(),
                );
              },
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if(selectedPeople.isNotEmpty) {
                    setState(() {
                      showExpenseDetails = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one person.')),
                    );
                  }
                },
                child: const Center(
                  child: Text(
                    "Next",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),

            if (showExpenseDetails) _buildExpenseDetailsUI(),
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

              // Category Dropdown
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

              // Payer Selection
              Row(
                children: [
                  const Text("Paid by: ",
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
                            totalAmount: totalAmount,  // Ensure updated totalAmount is passed
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
