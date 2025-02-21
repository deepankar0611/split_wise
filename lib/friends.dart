import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:split_wise/split/final_split_screen.dart';
import 'payer_selection_sheet.dart';
import 'dart:ui';

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
    payerAmounts = Map.from(widget.payerAmounts); // Initialize payerAmounts
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
        backgroundColor: const Color(0xFF234567),
        elevation: 4,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (totalAmount > 0 && expenseDescription.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinalSplitScreen(
                      selectedPeople: selectedPeople,
                      payerAmounts: payerAmounts,
                      totalAmount: totalAmount,
                      expenseDescription: expenseDescription,
                      selectedCategory: selectedCategory,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount and description.')),
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
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Split with:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF234567),
                        ),
                      ),
                      Text(
                        "${selectedPeople.length} selected",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: selectedPeople.isEmpty ? 0 : null,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: selectedPeople.map((friend) {
                        return Chip(
                          label: Text(
                            friend['name'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          avatar: CircleAvatar(
                            radius: 14,
                            backgroundImage: friend['profilePic'].isNotEmpty
                                ? NetworkImage(friend['profilePic'])
                                : null,
                            backgroundColor: Colors.grey[300],
                            child: friend['profilePic'].isEmpty
                                ? Text(
                              friend['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                                : null,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _toggleSelection(friend),
                          backgroundColor: const Color(0xFF234567).withOpacity(0.1),
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search friends...",
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              searchQuery = "";
                              displayFriends = List.from(friends);
                            });
                          },
                        )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                          displayFriends = friends
                              .where((friend) => friend["name"].toLowerCase().contains(searchQuery))
                              .toList();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 300, // Increased height for better visibility
              color: Colors.white,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: displayFriends.length,
                itemBuilder: (context, index) {
                  return _buildFriendItem(displayFriends[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF234567),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  minimumSize: const Size(double.infinity, 60),
                ),
                onPressed: selectedPeople.isEmpty
                    ? null
                    : () {
                  setState(() {
                    showExpenseDetails = true;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Continue (${selectedPeople.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600), // Increased duration for smoother animation
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1), // Start from bottom
                    end: Offset.zero, // End at current position
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic, // Smooth easing for slide-up
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: showExpenseDetails
                  ? _buildExpenseDetailsUI()
                  : const SizedBox.shrink(),
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
    return Card(
      margin: const EdgeInsets.all(0), // No margin to align with screen edges
      elevation: 8, // Slight elevation for shadow
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // Rounded bottom corners
      ),
      color: Colors.blueGrey[50], // Different color for contrast (light pastel blue-grey)
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selected Friends",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: selectedPeople.map((friend) {
                return Chip(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  label: Text(
                    friend["name"],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  avatar: CircleAvatar(
                    backgroundImage: friend["profilePic"].isNotEmpty
                        ? NetworkImage(friend["profilePic"])
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: friend["profilePic"].isEmpty
                        ? Text(
                      friend["name"][0],
                      style: const TextStyle(color: Colors.white),
                    )
                        : null,
                  ),
                  backgroundColor: Colors.grey[200],
                  elevation: 1,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              "Total Amount",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter total amount",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.currency_rupee, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  totalAmount = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              "Category",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _showCategoryBackdrop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco_rounded, color: Colors.blueGrey, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          selectedCategory,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Add expense description",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.description, color: Colors.black54),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  expenseDescription = value;
                });
              },
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Multiple User Payment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF234567),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text("Select Payers", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBackdrop(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF234567),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(
                        _getCategoryIcon(category),
                        color: isSelected ? const Color(0xFF234567) : Colors.grey[600],
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF234567) : Colors.grey[800],
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: const Color(0xFF234567))
                          : null,
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Grocery":
        return Icons.shopping_cart;
      case "Medicine":
        return Icons.local_pharmacy;
      case "Food":
        return Icons.restaurant;
      case "Rent":
        return Icons.home;
      case "Travel":
        return Icons.directions_car;
      case "Shopping":
        return Icons.shopping_bag;
      case "Entertainment":
        return Icons.movie;
      case "Utilities":
        return Icons.lightbulb;
      case "Others":
        return Icons.category;
      default:
        return Icons.category;
    }
  }
}