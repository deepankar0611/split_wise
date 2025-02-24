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
        DocumentSnapshot friendDoc =
        await FirebaseFirestore.instance.collection('users').doc(friendUid).get();

        if (friendDoc.exists) {
          final data = friendDoc.data() as Map<String, dynamic>?;
          fetchedFriends.add({
            "uid": friendUid,
            "name": data?['name'] ?? "Unknown",
            "profilePic": data?['profileImageUrl'] ?? "",
          });
        }
      }

      if (mounted) {
        setState(() {
          friends = fetchedFriends;
          displayFriends = List.from(friends);
        });
      }
    } catch (e) {
      print("Error fetching friends: $e");
      if (mounted) {
        setState(() {
          friends = [];
          displayFriends = [];
        });
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.08), // 8% of screen height
        child: AppBar(
          title: Text(
            "Add Expense",
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.055, // Responsive font size
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: const Color(0xFF1A3C6D),
          elevation: 0,
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Placeholder(), // Replace with your actual screen
                  ),
                );
              },
              child: Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.025, screenWidth * 0.04, screenHeight * 0.015),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(screenWidth * 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: screenWidth * 0.025,
                    offset: Offset(0, screenWidth * 0.01),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Split With",
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A3C6D),
                        ),
                      ),
                      Text(
                        "${selectedPeople.length} selected",
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Wrap(
                      spacing: screenWidth * 0.025,
                      runSpacing: screenHeight * 0.012,
                      children: selectedPeople.map((friend) {
                        return Chip(
                          label: Text(
                            friend['name'],
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                          avatar: CircleAvatar(
                            radius: screenWidth * 0.035,
                            backgroundImage: friend['profilePic'].isNotEmpty
                                ? NetworkImage(friend['profilePic'])
                                : null,
                            backgroundColor: Colors.blueGrey[100]!,
                            child: friend['profilePic'].isEmpty
                                ? Text(
                              friend['name'][0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            )
                                : null,
                          ),
                          deleteIcon: Icon(Icons.close, size: screenWidth * 0.045, color: Colors.grey),
                          onDeleted: () => _toggleSelection(friend),
                          backgroundColor: Colors.blueGrey[50]!,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.005),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search friends...",
                      hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                      prefixIcon: Icon(Icons.search, color: Colors.grey, size: screenWidth * 0.06),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey, size: screenWidth * 0.06),
                        onPressed: () {
                          setState(() {
                            searchQuery = "";
                            displayFriends = List.from(friends);
                          });
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100]!,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.075),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    ),
                    style: TextStyle(fontSize: screenWidth * 0.04),
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
              height: screenHeight * 0.35, // 35% of screen height
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: screenWidth * 0.025,
                    offset: Offset(0, screenWidth * 0.01),
                  ),
                ],
              ),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: displayFriends.length,
                itemBuilder: (context, index) {
                  return _buildFriendItem(displayFriends[index], screenWidth, screenHeight);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6D),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  elevation: 5,
                  minimumSize: Size(double.infinity, screenHeight * 0.075),
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
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Icon(Icons.arrow_forward_ios, size: screenWidth * 0.045),
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
                  ? _buildExpenseDetailsUI(screenWidth, screenHeight)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend, double screenWidth, double screenHeight) {
    bool isSelected = selectedPeople.any((p) => p['uid'] == friend["uid"]);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.005),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueGrey[50] : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: isSelected ? const Color(0xFF1A3C6D) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: screenWidth * 0.05,
          backgroundImage: friend["profilePic"].isNotEmpty ? NetworkImage(friend["profilePic"]) : null,
          backgroundColor: Colors.blueGrey[100]!,
          child: friend["profilePic"].isEmpty
              ? Text(
            friend["name"][0],
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
            ),
          )
              : null,
        ),
        title: Text(
          friend["name"],
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _toggleSelection(friend),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: const Color(0xFF1A3C6D), size: screenWidth * 0.06)
            : null,
      ),
    );
  }

  Widget _buildExpenseDetailsUI(double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.075)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: screenWidth * 0.05,
            offset: Offset(0, -screenWidth * 0.012),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Expense Details",
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3C6D),
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
          Text(
            "Total Amount",
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          TextField(
            decoration: InputDecoration(
              hintText: "Enter amount",
              hintStyle: TextStyle(fontSize: screenWidth * 0.04),
              prefixIcon: Icon(Icons.currency_rupee, color: const Color(0xFF1A3C6D), size: screenWidth * 0.06),
              filled: true,
              fillColor: Colors.grey[100]!,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: const BorderSide(color: Color(0xFF1A3C6D)),
              ),
            ),
            style: TextStyle(fontSize: screenWidth * 0.04),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                totalAmount = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          SizedBox(height: screenHeight * 0.025),
          Text(
            "Category",
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          GestureDetector(
            onTap: () => _showCategoryBackdrop(context, screenWidth, screenHeight),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.017),
              decoration: BoxDecoration(
                color: Colors.grey[100]!,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getCategoryIcon(selectedCategory), color: const Color(0xFF1A3C6D), size: screenWidth * 0.06),
                      SizedBox(width: screenWidth * 0.025),
                      Text(
                        selectedCategory,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey, size: screenWidth * 0.06),
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
          Text(
            "Description",
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          TextField(
            decoration: InputDecoration(
              hintText: "What’s this expense for?",
              hintStyle: TextStyle(fontSize: screenWidth * 0.04),
              prefixIcon: Icon(Icons.description, color: const Color(0xFF1A3C6D), size: screenWidth * 0.06),
              filled: true,
              fillColor: Colors.grey[100]!,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: const BorderSide(color: Color(0xFF1A3C6D)),
              ),
            ),
            style: TextStyle(fontSize: screenWidth * 0.04),
            onChanged: (value) {
              setState(() {
                expenseDescription = value;
              });
            },
          ),
          SizedBox(height: screenHeight * 0.025),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Paid By",
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
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
                  backgroundColor: const Color(0xFF1A3C6D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.012,
                  ),
                ),
                child: Text(
                  "Select Payers",
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoryBackdrop(BuildContext context, double screenWidth, double screenHeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: screenHeight * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.06)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Category",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A3C6D),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey, size: screenWidth * 0.06),
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
                        size: screenWidth * 0.06,
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1A3C6D) : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: const Color(0xFF1A3C6D), size: screenWidth * 0.06)
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