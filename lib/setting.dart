import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Define a lighter dark background color
const Color backgroundColor = Color(0xFF24242F); // Slightly lighter and desaturated dark blue

// Define a clearer color palette
const Color primaryColor = Color(0xFF00BCD4); // Teal for primary actions & highlights
const Color accentColor = Color(0xFF90CAF9); // Light blue for secondary accents
const Color cardColor = Color(0xFF333340); // Slightly lighter card background
const Color textColorPrimary = Colors.white; // White for primary text
const Color textColorSecondary = Colors.grey; // Grey for secondary text
const Color dividerColor = Colors.grey; // Grey for dividers
const Color iconColor = Colors.white70; // White-ish for icons
const Color settledColor = Color(0xFF80CBC4); // Light Teal for "Settled" status
const Color paidColor = Colors.greenAccent; // Green for "Paid" indicators
const Color discardedColor = Color(0xFFFFB74D); // Amber for "Discarded" status
const Color commentSectionBgColor = Color(0xFF42424F); // Darker grey for comment section background
const Color commentTileBgColor = Color(0xFF4A4A57); // Darker grey for comment tiles


class HistoryScreen extends StatelessWidget {
  // Mock data for demonstration - ONLY ONE ITEM NOW
  final SplitHistoryItem historyItem = SplitHistoryItem(
    date: DateTime.now().subtract(const Duration(days: 2)),
    description: "Weekend Getaway",
    addedDate: DateTime.now().subtract(const Duration(days: 2)),
    dueDate: DateTime.now().add(const Duration(days: 2)),
    totalAmount: 2000.00,
    settlementSummary: "Settled on Time",
    peopleInvolved: ["Deep", "Kartheek"],
    details: {
      "Expense": 2000.00,
      "Deep Received": 1000.00,
      "Kartheek Paid": 1000.00,
    },
    comments: [
      CommentItem(
        userName: "System",
        commentText: "This is a priority bill which needs to be settled within 5 days.",
        date: DateTime.now().subtract(const Duration(days: 1)),
        isPaid: false,
      ),
      CommentItem(
        userName: "System",
        commentText: "7020826685 paid ₹1000.00 to Deep.",
        date: DateTime.now().subtract(const Duration(days: 1)),
        isPaid: true,
        isDiscarded: true,
      ),
      CommentItem(
        userName: "System",
        commentText: "Expense settled within the due date.",
        date: DateTime.now().subtract(const Duration(days: 1)),
        isPaid: false,
      ),
    ],
  );

  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(LucideIcons.chevronLeft, color: iconColor), // White-ish back arrow
        title: const Text('Expense', style: TextStyle(color: textColorPrimary)), // White title
        titleTextStyle: const TextStyle(color: textColorPrimary, fontWeight: FontWeight.normal, fontSize: 20),
        backgroundColor: cardColor, // Card color AppBar background
        centerTitle: false,
        elevation: 2, // Added elevation for AppBar
        shadowColor: Colors.black26, // Shadow for AppBar
        iconTheme: IconThemeData(color: iconColor), // White-ish icon theme
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: IconButton(
              icon: Icon(LucideIcons.trash2, color: textColorSecondary), // Grey trash icon
              onPressed: () {
                // TODO: Implement delete functionality
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: IconButton(
              icon: Icon(LucideIcons.share2, color: textColorSecondary), // Grey share icon
              onPressed: () {
                // TODO: Implement share functionality
              },
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor, // Using defined dark background
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15.0), // Increased vertical padding on body
          child: HistoryTile(item: historyItem),
        ),
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final SplitHistoryItem item;

  const HistoryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card( // Using Card widget for the entire tile
      color: cardColor, // Card background color
      elevation: 3, // Increased elevation for more shadow
      shadowColor: Colors.black38, // Darker shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded corners for the card
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Increased padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card( // Card for Top Container
              color: commentSectionBgColor, // Darker background for top container card
              elevation: 1, // Slight elevation for inner card
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners for inner card
              child: Padding(
                padding: const EdgeInsets.all(15.0), // Increased padding for top container
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0), // Increased padding for icon container
                      decoration: BoxDecoration(
                        color: accentColor, // Light blue icon background
                        borderRadius: BorderRadius.circular(12), // More rounded corners for icon background
                      ),
                      child: Icon(LucideIcons.shoppingCart, color: iconColor, size: 30), // White-ish cart icon, increased size
                    ),
                    const SizedBox(width: 20), // Increased spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Added on ${DateFormat('d\'th\' MMM').format(item.addedDate)}",
                          style: TextStyle(color: textColorSecondary, fontSize: 15), // Slightly larger font size
                        ),
                        Text(
                          item.description,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500, color: textColorPrimary), // Increased font size, white text
                        ),
                        Text(
                          DateFormat('d\'th\' MMMJahr').format(item.date),
                          style: TextStyle(color: textColorSecondary, fontSize: 16), // Slightly larger font size
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30), // Increased spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "₹${item.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 32, color: textColorPrimary), // Even larger amount, white text
                ),
              ],
            ),
            const SizedBox(height: 20), // Increased spacing
            Divider(color: dividerColor, thickness: 0.8), // Thicker divider
            const SizedBox(height: 15), // Increased spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Settlement",
                  style: TextStyle(fontSize: 18, color: textColorPrimary), // Slightly larger font size, white text
                ),
                Text(
                  "Due date",
                  style: TextStyle(fontSize: 16, color: textColorSecondary), // Slightly larger font size, grey text
                ),
              ],
            ),
            const SizedBox(height: 10), // Increased spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "No money moved in-app.\nExternal payments only.",
                  style: TextStyle(fontSize: 15, color: textColorSecondary, height: 1.5), // Slightly larger font size, grey text
                ),
                Text(
                  DateFormat('d\'th\' MMM').format(item.dueDate),
                  style: const TextStyle(fontSize: 18, color: textColorPrimary, fontWeight: FontWeight.w500), // Slightly larger font size, white text
                ),
              ],
            ),
            const SizedBox(height: 25), // Increased spacing
            Align(
              alignment: Alignment.centerLeft, // Align settlement summary to left
              child: Card( // Card for Settlement Summary - Aligned Left Now
                color: settledColor, // Light teal status background
                elevation: 2, // Elevation for status card
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // More rounded corners
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Increased padding for status text
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Make the Row shrink to fit content
                    children: [
                      Text(
                        item.settlementSummary,
                        style: const TextStyle(color: textColorPrimary, fontWeight: FontWeight.w500, fontSize: 17), // Adjusted font size, white text
                      ),
                      const SizedBox(width: 10),
                      Icon(LucideIcons.checkCircle2, color: textColorPrimary, size: 22), // White checkmark for better visibility
                    ],
                  ),
                ),
              ),
            ),


            const SizedBox(height: 30), // Increased spacing
            Card( // Card for Person Details
              color: cardColor, // Card background color
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners for person card
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Increased padding for person card
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25, // Increased avatar radius
                          backgroundColor: primaryColor, // Teal avatar background
                          child: Icon(LucideIcons.user, color: textColorPrimary, size: 26), // White user icon, increased size
                        ),
                        const SizedBox(width: 20), // Increased spacing
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Deep",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColorPrimary), // Slightly larger font size, white text
                            ),
                            Text(
                              "Add UPI ID",
                              style: TextStyle(fontSize: 14, color: accentColor), // Light blue UPI link
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Received",
                              style: TextStyle(fontSize: 16, color: textColorSecondary), // Slightly larger font size, grey text
                            ),
                            const SizedBox(width: 12), // Increased spacing
                            Text(
                              "Due",
                              style: TextStyle(fontSize: 16, color: textColorSecondary), // Slightly larger font size, grey text
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "₹${item.details["Deep Received"]?.toStringAsFixed(0) ?? '0'}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColorPrimary), // Slightly larger font size, white text
                            ),
                            const SizedBox(width: 12), // Increased spacing
                            Card(
                              color: settledColor, // Light teal "Settled" background
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // More rounded corners
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Adjusted padding
                                child: Text(
                                  "Settled",
                                  style: const TextStyle(color: textColorPrimary, fontWeight: FontWeight.w500, fontSize: 16), // Slightly larger font size, white text
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Increased spacing

            Card( // Card for Expansion Tiles Container
              color: cardColor, // Card background color
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners for expansion tiles card
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0), // Vertical padding for expansion tiles
                child: Column(
                  children: [
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20), // Added horizontal padding
                      title: Text("Who Will Pay", style: TextStyle(fontSize: 18, color: textColorPrimary)), // Slightly larger font size, white text
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Divider(color: dividerColor, thickness: 0.8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: true,
                                    onChanged: (bool? value) {
                                      // TODO: Implement checkbox logic if needed
                                    },
                                    activeColor: paidColor, // Green active checkbox color
                                    checkColor: textColorPrimary, // White check color
                                  ),
                                  Text(
                                    "Kartheek",
                                    style: TextStyle(fontSize: 18, color: textColorPrimary), // Slightly larger font size, white text
                                  ),
                                ],
                              ),
                              Text(
                                "Paid ₹1000",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColorPrimary), // Slightly larger font size, white text
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20), // Added horizontal padding
                      title: Text("Who Will Get", style: TextStyle(fontSize: 18, color: textColorPrimary)), // Slightly larger font size, white text
                      children: [
                        Divider(color: dividerColor, thickness: 0.8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Text("No details available", style: TextStyle(color: textColorSecondary, fontSize: 16)), // Slightly larger font size, grey text
                        ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20), // Added horizontal padding
                      title: Text("Overall Summary", style: TextStyle(fontSize: 18, color: textColorPrimary)), // Slightly larger font size, white text
                      children: [
                        Divider(color: dividerColor, thickness: 0.8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Text("Summary details here", style: TextStyle(color: textColorSecondary, fontSize: 16)), // Slightly larger font size, grey text
                        ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20), // Added horizontal padding
                      title: Text("Bills", style: TextStyle(fontSize: 18, color: textColorPrimary)), // Slightly larger font size, white text
                      children: [
                        Divider(color: dividerColor, thickness: 0.8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Text("Bills information here", style: TextStyle(color: textColorSecondary, fontSize: 16)), // Slightly larger font size, grey text
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 30), // Increased spacing

            // Comments Section Starts Here
            Card( // Card for Comments Section
              color: commentSectionBgColor, // Darker grey card for comments section
              elevation: 3, // Increased elevation for comment card
              shadowColor: Colors.black38, // Darker shadow
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded corners
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0), // Increased padding
                    child: Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColorPrimary)), // Slightly larger font size, white text
                  ),
                  Divider(color: dividerColor, thickness: 0.8),
                  SizedBox(
                    height: 220, // Increased height for comments list
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: item.comments.length,
                      itemBuilder: (context, index) {
                        final comment = item.comments[index];
                        return CommentTile(comment: comment);
                      },
                    ),
                  ),
                  Divider(color: dividerColor, thickness: 0.8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15), // Increased padding
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Add a comment",
                              hintStyle: TextStyle(color: textColorSecondary, fontSize: 16), // Slightly larger font size, grey hint text
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 16, color: textColorPrimary), // Slightly larger font size, white input text
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.send, color: textColorSecondary), // Grey send icon
                          iconSize: 24, // Slightly larger icon
                          onPressed: () {
                            // TODO: Implement send comment functionality
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), // Increased spacing
          ],
        ),
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final CommentItem comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: commentTileBgColor, // Darker grey background for comment tiles
      padding: const EdgeInsets.all(15.0), // Increased padding for comment tiles
      margin: const EdgeInsets.only(bottom: 3.0), // Slightly increased margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.messageSquare, color: iconColor, size: 24), // White-ish message icon, increased size
              const SizedBox(width: 12), // Increased spacing
              Expanded(
                child: Text(
                  comment.commentText,
                  style: const TextStyle(fontSize: 16, color: textColorPrimary, height: 1.4), // Slightly larger font size, white text
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Increased spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('Yesterday').format(comment.date),
                    style: TextStyle(fontSize: 14, color: textColorSecondary), // Slightly larger font size, grey text
                  ),
                  const SizedBox(width: 10), // Increased spacing
                  Icon(LucideIcons.checkCircle, color: paidColor, size: 18), // Green checkmark icon, increased size
                ],
              ),
              if (comment.isDiscarded == true)
                Text(
                  "discard",
                  style: TextStyle(fontSize: 14, color: discardedColor, fontWeight: FontWeight.w500), // Amber "discard" text
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class SplitHistoryItem {
  final DateTime date;
  final DateTime addedDate;
  final DateTime dueDate;
  final String description;
  final double totalAmount;
  final String settlementSummary;
  final List<String> peopleInvolved;
  final Map<String, dynamic> details;
  final List<CommentItem> comments;

  SplitHistoryItem({
    required this.date,
    required this.addedDate,
    required this.dueDate,
    required this.description,
    required this.totalAmount,
    required this.settlementSummary,
    required this.peopleInvolved,
    required this.details,
    this.comments = const [],
  });
}

class CommentItem {
  final String userName;
  final String commentText;
  final DateTime date;
  final bool isPaid;
  final bool isDiscarded;

  CommentItem({
    required this.userName,
    required this.commentText,
    required this.date,
    this.isPaid = false,
    this.isDiscarded = false,
  });
}