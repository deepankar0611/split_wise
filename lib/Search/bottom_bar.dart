import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:split_wise/friends.dart';
import 'package:split_wise/home_screen.dart';
import 'package:split_wise/login.dart';
import '../login_screen.dart';
import '../profile_overview.dart';
import 'search_bar.dart';
import 'package:split_wise/friends.dart'; // Ensure this is imported if needed.

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _selectedIndex = 0;

  // Screens for each Bottom Navigation item
  final List<Widget> _screens = [
    const HomeScreen(),                // Home Screen
    const FriendsListScreen(),         // Friends Search/Request Screen
    const AddExpenseScreen(),          // Expense Creation Screen
    const ProfileOverviewScreen(),     // Profile Overview Screen
  ];

  // Handle Bottom Navigation Tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Friends"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
