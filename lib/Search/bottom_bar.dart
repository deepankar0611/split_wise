import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_wise/search_bar.dart';
import 'package:split_wise/friends.dart';
import 'package:split_wise/home_screen.dart';
import 'package:split_wise/login.dart';
import '../profile_overview.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FriendsListScreen(),
    const AddExpenseScreen(payerAmounts: {}),
    const ProfileOverviewScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedIndex();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('selectedIndex') ?? 0;
    });
  }

  void _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('selectedIndex', index);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _controller.reset();
      setState(() {
        _selectedIndex = index;
        _saveSelectedIndex(index);
      });
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return IndexedStack(
            index: _selectedIndex,
            children: _screens.map((widget) {
              final isCurrent = _screens.indexOf(widget) == _selectedIndex;
              return AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isCurrent ? 1.0 : (1.0 - _animation.value * 0.1),
                    child: Opacity(
                      opacity: isCurrent ? 1.0 : (1.0 - _animation.value),
                      child: Transform.translate(
                        offset: Offset(0, _animation.value * (isCurrent ? -10 : 10)),
                        child: widget,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Color(0xFF1A2E39), // Color of the curved bar
        buttonBackgroundColor: Color(0xFF1A2E39), // Color of the center button
        height: 60,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 300),
        index: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          Icon(CupertinoIcons.home, size: 30, color: Colors.white),
          Icon(CupertinoIcons.person_2, size: 30, color: Colors.white),
          Icon(CupertinoIcons.add_circled, size: 30, color: Colors.white),
          Icon(CupertinoIcons.profile_circled, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}