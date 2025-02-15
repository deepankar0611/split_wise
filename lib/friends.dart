import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  List<Map<String, dynamic>> friends = [];
  List<String> selectedPeople = [];
  bool isLoading = true;
  bool showExpenseDetails = false;
  String searchQuery = "";
  String selectedCategory = "Grocery";
  double totalAmount = 0.0;

  final List<String> categories = [
    "Grocery", "Medicine", "Food", "Rent", "Travel",
    "Shopping", "Entertainment", "Utilities", "Others"
  ];




  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    print("Fetching friends for user: $userId"); // Debugging

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      print("🔥 Friends found: ${snapshot.docs.length}");

      if (!mounted) return; // ✅ Prevent calling setState() if widget is disposed

      setState(() {
        friends = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          return {
            "uid": doc.id,
            "name": data.containsKey("name") ? data["name"] : "Unknown",
            "email": data.containsKey("email") ? data["email"] : "No Email",
            "profilePic": data.containsKey("profilePic") ? data["profilePic"] : "",
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching friends: $e");
      if (!mounted) return; // ✅ Prevent calling setState() if widget is disposed
      setState(() => isLoading = false);
    }
  }



  void _toggleSelection(String name) {
    setState(() {
      selectedPeople.contains(name)
          ? selectedPeople.remove(name)
          : selectedPeople.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add an expense"),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
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
                  children: selectedPeople
                      .map((name) => Chip(
                    label: Text(name),
                    avatar: const CircleAvatar(backgroundColor: Colors.grey),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _toggleSelection(name),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search friends...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : friends.isEmpty
                ? const Center(child: Text("No friends found"))
                : ListView(
              children: friends
                  .where((friend) =>
                  friend["name"].toLowerCase().contains(searchQuery))
                  .map((friend) => _buildFriendItem(friend))
                  .toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => setState(() => showExpenseDetails = true),
              child: const Center(
                child: Text("Submit", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ),

          if (showExpenseDetails) _buildExpenseDetailsUI(),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
        friend["profilePic"].isNotEmpty ? NetworkImage(friend["profilePic"]) : null,
        backgroundColor: Colors.grey,
        child: friend["profilePic"].isEmpty ? Text(friend["name"][0]) : null,
      ),
      title: Text(friend["name"]),
      subtitle: Text(friend["email"]),
      onTap: () => _toggleSelection(friend["name"]),
      trailing: selectedPeople.contains(friend["name"])
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
                children: selectedPeople
                    .map((name) => Chip(label: Text(name), avatar: const CircleAvatar(backgroundColor: Colors.grey)))
                    .toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "Enter a description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "₹ 0.00",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (value) => setState(() => selectedCategory = value!),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
