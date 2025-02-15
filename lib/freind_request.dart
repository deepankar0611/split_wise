import 'package:flutter/material.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> users = [
    {"name": "Alice Johnson", "email": "alice@email.com", "requested": false},
    {"name": "Bob Smith", "email": "bob@email.com", "requested": true},
    {"name": "Charlie Brown", "email": "charlie@email.com", "requested": false},
  ];

  void sendFriendRequest(int index) {
    setState(() {
      users[index]['requested'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Friend request sent to ${users[index]['name']}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends List"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search friends...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Refresh UI on search
              },
            ),
            const SizedBox(height: 20),
            // User List
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isRequested = user['requested'];
                  if (_searchController.text.isNotEmpty &&
                      !user['name'].toLowerCase().contains(_searchController.text.toLowerCase())) {
                    return const SizedBox();
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(user['name'][0]), // First letter of name
                      ),
                      title: Text(user['name']),
                      subtitle: Text(user['email']),
                      trailing: isRequested
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                        onPressed: () => sendFriendRequest(index),
                        child: const Text("Add Friend"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
