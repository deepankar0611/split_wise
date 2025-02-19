import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_wise/Search/search_bar.dart';
import 'package:split_wise/friends.dart';
import 'package:split_wise/home_screen.dart';
import 'package:split_wise/login.dart';
import '../profile_overview.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF1A2E39),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 13,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            activeIcon: Icon(CupertinoIcons.home, color: Color(0xFF1A2E39)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill, color: Color(0xFF1A2E39)),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            activeIcon: Icon(CupertinoIcons.add_circled_solid, color: Color(0xFF1A2E39)),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.profile_circled),
            activeIcon: Icon(CupertinoIcons.profile_circled, color: Color(0xFF1A2E39)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}