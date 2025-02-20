import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:split_wise/notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 220.0,
            backgroundColor: const Color(0xFF234567),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final collapseProgress = (220.0 - constraints.biggest.height) / (220.0 - kToolbarHeight);
                final cardAnimationProgress = collapseProgress.clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                  title: null,
                  background: Padding(
                    padding: const EdgeInsets.only(top: 90.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Transform.translate(
                        offset: Offset(0, cardAnimationProgress * 70),
                        child: Transform.scale(
                          scale: 1.0 - cardAnimationProgress * 0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildReceiveCard(),
                                _buildPayCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                radius: 20, // Adjust radius as needed
                backgroundColor: Colors.grey, // Placeholder background color
                child: Icon(LucideIcons.user, color: Colors.white), // Placeholder icon
              ),
              onPressed: () {
                // TODO: Open profile page or perform profile action
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Notificationn()),
                  );
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildBodyCard(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCard() {
    return Container(
      decoration: BoxDecoration(
        color:  Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          _buildHistoryCardBox(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(LucideIcons.dollarSign, "Proceed to Payment"),
        _buildActionButton(LucideIcons.send, "Send Reminder"),
        _buildActionButton(LucideIcons.share, "Share Payment", onTap: () {
          // Example onTap action, you can customize this
        }),
      ],
    );
  }


  Widget _buildReceiveCard() {
    return Container(
      width: 170,
      height: 120, // Height is already increased to 120
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Changed mainAxisSize to min
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Further reduced padding
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8), // Slightly smaller borderRadius
              ),
              child: const Text(
                "Receive",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 9, // Even smaller font size
                ),
                maxLines: 1, // Ensure single line
                overflow: TextOverflow.ellipsis, // Handle overflow if it somehow occurs
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Text(
              "₹266.67",
              style: const TextStyle(
                fontSize: 26, // Further reduced font size
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.0, bottom: 4.0),
            child: Text(
              "will get",
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
                fontSize: 13, // Further reduced font size
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayCard() {
    return Container(
      width: 170,
      height: 120, // Height is already increased to 120
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Changed mainAxisSize to min
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Further reduced padding
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8), // Slightly smaller borderRadius
              ),
              child: const Text(
                "Pay",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 9, // Even smaller font size
                ),
                maxLines: 1, // Ensure single line
                overflow: TextOverflow.ellipsis, // Handle overflow if it somehow occurs
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Text(
              "₹0",
              style: const TextStyle(
                fontSize: 26, // Further reduced font size
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.0, bottom: 4.0),
            child: Text(
              "will pay",
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 13, // Further reduced font size
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHistoryCardBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Priority Bills",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildHistoryItem(
                  title: "Netflix",
                  date: "Feb 20, 2025",
                  amount: "-\$25.00",
                  color: Colors.blueAccent,
                  settled: index % 2 == 0,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required String amount,
    required Color color,
    bool settled = false,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (settled)
                const Icon(LucideIcons.zap, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            settled ? "settled" : date,
            style: TextStyle(
                color: settled ? Colors.green[600] : Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (!settled)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                amount,
                style: TextStyle(
                  color: amount.startsWith('+') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF234567),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF234567),
                fontSize: 14,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final List<Map<String, dynamic>> transactions = [
      {"icon": LucideIcons.car, "title": "Uber", "subtitle": "He paid \$39.60", "amount": "-\$19.80", "color": Colors.orange},
      {"icon": LucideIcons.shoppingCart, "title": "Groceries", "subtitle": "You paid \$124.16", "amount": "+\$62.08", "color": Colors.teal},
      {"icon": LucideIcons.mapPin, "title": "Adventures", "subtitle": "Shared group", "amount": "-\$15.99", "color": Colors.blueAccent},
      {"icon": LucideIcons.film, "title": "Cinema", "subtitle": "He paid \$40.00", "amount": "-\$20.00", "color": Colors.purple},
      {"icon": LucideIcons.gift, "title": "Present for Andy", "subtitle": "He paid \$64.30", "amount": "-\$64.30", "color": Colors.pinkAccent},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: transactions.length,
            itemBuilder: (context, index) => _buildTransactionItem(
              transactions[index]['icon'],
              transactions[index]['title'],
              transactions[index]['subtitle'],
              transactions[index]['amount'],
              transactions[index]['color'],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTransactionItem(IconData icon, String title, String subtitle, String amount, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          trailing: Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: amount.startsWith('+') ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}