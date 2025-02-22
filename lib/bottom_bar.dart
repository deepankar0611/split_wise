import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:split_wise/Home%20screen/home_screen.dart';
import 'package:split_wise/Profile/profile_overview.dart';
import 'package:split_wise/Search/search_bar.dart';
import 'package:split_wise/split/friends.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isBottomBarVisible = true;
  bool _handlingScroll = false;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _screens.addAll([
      HomeScreen(scrollController: _scrollController),
      const FriendsListScreen(),
      const AddExpenseScreen(payerAmounts: {}),
      const ProfileOverviewScreen(),
    ]);

    _scrollController.addListener(_onScrollDirectionChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollDirectionChange() {
    if (_handlingScroll) return;

    print("Scroll direction changed!");
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      print("Scrolling DOWN");
      if (_isBottomBarVisible) {
        _hideBottomBar();
      }
    }
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      print("Scrolling UP");
      if (!_isBottomBarVisible) {
        _showBottomBar();
      }
    }
  }

  void _hideBottomBar() {
    _handlingScroll = true;
    if (_isBottomBarVisible) {
      print("Hiding Bottom Bar FUNCTION CALLED");
      setState(() {
        _isBottomBarVisible = false;
      });
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      _handlingScroll = false;
    });
  }

  void _showBottomBar() {
    _handlingScroll = true;
    if (!_isBottomBarVisible) {
      print("Showing Bottom Bar FUNCTION CALLED");
      setState(() {
        _isBottomBarVisible = true;
      });
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      _handlingScroll = false;
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _controller.reset();
      setState(() {
        _selectedIndex = index;
        _showBottomBar();
      });
      _controller.forward();
    } else {
      _showBottomBar();
    }
  }

  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUserId';
  final SupabaseClient supabase = Supabase.instance.client;

  Map<String, dynamic> userData = {
    "name": "User",
    "email": "",
    "profileImageUrl": "",
    "phone_number": "",
    "amountToPay": "",
    "amountToReceive": "",
  };

  Future<void> _fetchUserData() async {
    if (userId == 'defaultUserId') return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          userData = {
            "name": data["name"] ?? "User",
            "email": data["email"] ?? "",
            "profileImageUrl": data.containsKey("profileImageUrl") ? data["profileImageUrl"] : "",
            "amountToPay": data["amountToPay"]?.toString() ?? "0",
            "amountToReceive": data["amountToReceive"]?.toString() ?? "0",
          };
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
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
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isBottomBarVisible ? 80.0 : 0.0, // Increased height to accommodate content
        curve: Curves.easeInOut,
        child: _isBottomBarVisible
            ? BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1A2E39),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 10, // Reduced unselected font size
          elevation: 8,
          iconSize: 24, // Reduced icon size
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home, color: Color(0xFF0288D1)),
              activeIcon: Icon(CupertinoIcons.home, color: Color(0xFF1A2E39)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_2, color: Color(0xFF7B1FA2)),
              activeIcon: Icon(CupertinoIcons.person_2, color: Color(0xFF1A2E39)),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.add_circled, color: Color(0xFFD81B60)),
              activeIcon: Icon(CupertinoIcons.add_circled, color: Color(0xFF1A2E39)),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.profile_circled, color: Color(0xFF00897B)),
              activeIcon: Icon(CupertinoIcons.profile_circled, color: Color(0xFF1A2E39)),
              label: 'Profile',
            ),
          ],
        )
            : null, // Avoid rendering BottomNavigationBar when height is 0
      ),
    );
  }
}