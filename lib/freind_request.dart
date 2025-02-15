import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> users = [
    {"name": "Alice Johnson", "email": "alice@email.com", "requested": false, "avatar": "A"},
    {"name": "Bob Smith", "email": "bob@email.com", "requested": true, "avatar": "B"},
    {"name": "Charlie Brown", "email": "charlie@email.com", "requested": false, "avatar": "C"},
  ];

  void sendFriendRequest(int index) {
    setState(() {
      users[index]['requested'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Friend request sent to ${users[index]['name']}"),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A2E39),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2E39), // Background color
      appBar: AppBar(
        title: const Text(
          "Friends List",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A2E39),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_add, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Shadow Effect
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3), // Light shadow
                    blurRadius: 6,
                    spreadRadius: 2,
                    offset: const Offset(0, 3), // Shadow at bottom
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search friends...",
                  prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF1A2E39)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled, color: Color(0xFF1A2E39)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),

          // User List
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isRequested = user['requested'];
                final String avatarText = user['avatar'];

                if (_searchController.text.isNotEmpty &&
                    !user['name'].toLowerCase().contains(_searchController.text.toLowerCase())) {
                  return const SizedBox();
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1A2E39),
                      child: Text(
                        avatarText,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(user['email'], style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    trailing: isRequested
                        ? const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.green, size: 28)
                        : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2E39),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => sendFriendRequest(index),
                      icon: const Icon(CupertinoIcons.person_add, size: 18, color: Colors.white),
                      label: const Text("Add", style: TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
