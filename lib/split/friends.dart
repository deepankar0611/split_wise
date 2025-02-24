import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:split_wise/split/final_split_screen.dart';
import 'dart:ui';
import 'package:split_wise/split/payer_selection_sheet.dart';

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
    payerAmounts = Map.from(widget.payerAmounts);
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      List<String> friendUids = await _getFriendUids();
      List<Map<String, dynamic>> fetchedFriends = [];

      for (String friendUid in friendUids) {
        DocumentSnapshot friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .get();

        if (friendDoc.exists) {
          final data = friendDoc.data() as Map<String, dynamic>?;
          fetchedFriends.add({
            "uid": friendUid,
            "name": data?['name'] ?? "Unknown",
            "profilePic": data?['profileImageUrl'] ?? "",
          });
        }
      }

      setState(() {
        friends = fetchedFriends;
        displayFriends = List.from(friends);
      });
    } catch (e) {
      print("Error fetching friends: $e");
      setState(() {
        friends = [];
        displayFriends = [];
      });
    }
  }

  Future<List<String>> _getFriendUids() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error fetching friend UIDs: $e");
      return [];
    }
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
      backgroundColor: const Color(0xFFF5F7FA), // Non-nullable Color
      appBar: AppBar(
        title: const Text(
          "Add Expense",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1A3C6D), // Solid background color
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Placeholder for save action - replace with your logic
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Placeholder(), // Replace Placeholder with your actual screen/widget
                ),
              );
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: const RoundedRectangleBorder( // Apply shape to AppBar
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
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
                        "Split With",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A3C6D),
                        ),
                      ),
                      Text(
                        "${selectedPeople.length} selected",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: selectedPeople.map((friend) {
                        return Chip(
                          label: Text(
                            friend['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          avatar: CircleAvatar(
                            radius: 14,
                            backgroundImage: friend['profilePic'].isNotEmpty
                                ? NetworkImage(friend['profilePic'])
                                : null,
                            backgroundColor: Colors.blueGrey[100]!, // Non-nullable
                            child: friend['profilePic'].isEmpty
                                ? Text(
                              friend['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                                : null,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onDeleted: () => _toggleSelection(friend),
                          backgroundColor: Colors.blueGrey[50]!, // Non-nullable
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search friends...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            searchQuery = "";
                            displayFriends = List.from(friends);
                          });
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100]!, // Non-nullable
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                ],
              ),
            ),
            Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
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
                  backgroundColor: const Color(0xFF1A3C6D), // Non-nullable
                  foregroundColor: Colors.white, // Non-nullable
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(opacity: animation, child: child),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueGrey[50] : Colors.white, // Non-nullable
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1A3C6D) : Colors.grey[200]!, // Non-nullable
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: friend["profilePic"].isNotEmpty
              ? NetworkImage(friend["profilePic"])
              : null,
          backgroundColor: Colors.blueGrey[100]!, // Non-nullable
          child: friend["profilePic"].isEmpty
              ? Text(friend["name"][0], style: const TextStyle(color: Colors.white))
              : null,
        ),
        title: Text(
          friend["name"],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onTap: () => _toggleSelection(friend),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF1A3C6D))
            : null,
      ),
    );
  }

  Widget _buildExpenseDetailsUI() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Expense Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3C6D),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Total Amount",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: "Enter amount",
              prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF1A3C6D)),
              filled: true,
              fillColor: Colors.grey[100]!, // Non-nullable
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A3C6D)),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                totalAmount = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "Category",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showCategoryBackdrop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100]!, // Non-nullable
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getCategoryIcon(selectedCategory), color: const Color(0xFF1A3C6D)),
                      const SizedBox(width: 10),
                      Text(
                        selectedCategory,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Description",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: "What’s this expense for?",
              prefixIcon: const Icon(Icons.description, color: Color(0xFF1A3C6D)),
              filled: true,
              fillColor: Colors.grey[100]!, // Non-nullable
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A3C6D)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                expenseDescription = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Paid By",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  backgroundColor: const Color(0xFF1A3C6D), // Non-nullable
                  foregroundColor: Colors.white, // Non-nullable
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text("Select Payers"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoryBackdrop(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3C6D),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
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
                      leading: Icon(
                        _getCategoryIcon(category),
                        color: isSelected ? const Color(0xFF1A3C6D) : Colors.grey[600]!,
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1A3C6D) : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF1A3C6D))
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