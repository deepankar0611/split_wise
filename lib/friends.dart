import 'package:flutter/material.dart';
import 'package:split_wise/payer_selection_sheet.dart';

import 'bottomsheet.dart';


class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  List<String> friends = [
    "John Doe",
    "Meghan Thomas",
    "Alan Bates",
    "Rahul Das",
    "Sarah Sengupta"
  ];
  List<String> groups = ["Room No 402", "Office Team"];
  List<String> selectedPeople = [];
  bool showExpenseDetails = false;
  String searchQuery = "";
  String selectedCategory = "Grocery"; // Default category
  List<String> selectedPayers = ["You"];
  Map<String, double> payerAmounts = {};
  double totalAmount = 0.0;
  double remainingAmount = 0.0;

  final List<String> categories = [
    "Grocery",
    "Medicine",
    "Food",
    "Rent",
    "Travel",
    "Shopping",
    "Entertainment",
    "Utilities",
    "Others"
  ];

  void _toggleSelection(String name) {
    setState(() {
      if (selectedPeople.contains(name)) {
        selectedPeople.remove(name);
      } else {
        selectedPeople.add(name);
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
            onPressed: () {},
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "With you and:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8.0,
                  children: selectedPeople
                      .map((name) => Chip(
                            label: Text(name),
                            avatar: const CircleAvatar(
                                backgroundColor: Colors.grey),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _toggleSelection(name),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Enter names, emails, or phone #s",
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

          // Filtered Friends and Groups List
          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle("Recent"),
                _buildFilteredList(["Room No 402"]),
                _buildSectionTitle("Groups"),
                _buildFilteredList(groups),
                _buildSectionTitle("Friends"),
                _buildFilteredList(friends),
              ],
            ),
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
                setState(() {
                  showExpenseDetails = true;
                });
              },
              child: const Center(
                child: Text(
                  "Submit",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),

          if (showExpenseDetails) _buildExpenseDetailsUI(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFilteredList(List<String> list) {
    final filteredList =
        list.where((name) => name.toLowerCase().contains(searchQuery)).toList();
    return Column(
      children: filteredList.map((name) => _buildContactItem(name)).toList(),
    );
  }

  Widget _buildContactItem(String name) {
    return ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.grey),
      title: Text(name),
      onTap: () => _toggleSelection(name),
      trailing: selectedPeople.contains(name)
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
          child: Column(children: [
            Wrap(
              spacing: 8.0,
              children: selectedPeople
                  .map((name) => Chip(
                        label: Text(name),
                        avatar:
                            const CircleAvatar(backgroundColor: Colors.grey),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter a description",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                prefixIcon: const Icon(Icons.description),
              ),
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
            ),
            const SizedBox(height: 10),

            // Dropdown for Expense Category
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
            Row(
              children: [
                const Text(
                  "Paid by: ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {

                  },
                  child:  TextButton(
                    onPressed: (){
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context)=>
                              PayerSelectionSheet(
                                  friends: friends,
                                  selectedPayers: selectedPayers,
                                  payerAmounts: payerAmounts,
                                  totalAmount: totalAmount,
                                  onSelectionDone: (updatedPayers, updatedAmounts) {
                                    setState(() {
                                      selectedPayers = updatedPayers;
                                      payerAmounts = updatedAmounts;
                                    });
                                  },
                              )
                          )
                      );
                    },
                    child: Text(
                      selectedPayers.length == 1
                          ? "You"
                          : "${selectedPayers.length}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal, // Highlight "You" as a button
                        decoration:
                        TextDecoration.underline, // Make it look clickable
                      ),
                    ),
                  ),
                ),
                const Text(
                  " and split equally",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ]),
        ),
      ],
    );
  }
}
