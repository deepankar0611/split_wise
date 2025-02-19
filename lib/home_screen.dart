import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:split_wise/profile_overview.dart';
import 'friends.dart';
import 'notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeader(),
              Positioned(
                bottom: -43,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(LucideIcons.dollarSign, "Proceed to Payment"),
                    _buildActionButton(LucideIcons.send, "Send Reminder"),
                    _buildActionButton(
                      LucideIcons.share,
                      "Share Payment",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileOverviewScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF234567),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.arrow_back_ios, color: Colors.white),
              const Text(
                "Peter Clarkson",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // 🔔 Notification Icon (Navigates to NotificationScreen)
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Notificationn()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Total:", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 5),
          const Text("-\$154,68", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 25,
            child: Icon(LucideIcons.dollarSign, color: Colors.blue, size: 24),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.blue, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    List<Map<String, dynamic>> transactions = [
      {"icon": LucideIcons.car, "title": "Uber", "subtitle": "He paid 39,60\$", "amount": "-\$19,80", "color": Colors.green},
      {"icon": LucideIcons.shoppingCart, "title": "Groceries", "subtitle": "You paid 124,16\$", "amount": "+\$62,08", "color": Colors.purple},
      {"icon": LucideIcons.map, "title": "Adventures", "subtitle": "Shared group", "amount": "-\$15,99", "color": Colors.blue},
      {"icon": LucideIcons.film, "title": "Cinema", "subtitle": "He paid 40\$", "amount": "-\$20,00", "color": Colors.grey},
      {"icon": LucideIcons.gift, "title": "Present for Andy", "subtitle": "He paid 64,30\$", "amount": "-\$64,30", "color": Colors.pink},
      {"icon": LucideIcons.car, "title": "Uber", "subtitle": "He paid 39,60\$", "amount": "-\$19,80", "color": Colors.green},
      {"icon": LucideIcons.shoppingCart, "title": "Groceries", "subtitle": "You paid 124,16\$", "amount": "+\$62,08", "color": Colors.purple},
      {"icon": LucideIcons.map, "title": "Adventures", "subtitle": "Shared group", "amount": "-\$15,99", "color": Colors.blue},
      {"icon": LucideIcons.film, "title": "Cinema", "subtitle": "He paid 40\$", "amount": "-\$20,00", "color": Colors.grey},
      {"icon": LucideIcons.gift, "title": "Present for Andy", "subtitle": "He paid 64,30\$", "amount": "-\$64,30", "color": Colors.pink},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(
          transactions[index]['icon'],
          transactions[index]['title'],
          transactions[index]['subtitle'],
          transactions[index]['amount'],
          transactions[index]['color'],
        );
      },
    );
  }

  Widget _buildTransactionItem(IconData icon, String title, String subtitle, String amount, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amount.startsWith('+') ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}