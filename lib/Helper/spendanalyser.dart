import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class SpendAnalyzerScreen extends StatefulWidget {
  const SpendAnalyzerScreen({super.key});

  @override
  State<SpendAnalyzerScreen> createState() => _SpendAnalyzerScreenState();
}

class _SpendAnalyzerScreenState extends State<SpendAnalyzerScreen> {
  String _timePeriod = 'Month';
  String _chartType = 'Spent';
  String _selectedChartType = 'Pie';
  DateTime _selectedDate = DateTime.now();
  String _selectedStatisticsCategory = 'Transport';
  int _touchedIndex = -1; // To track touched pie section

  final List<String> receivedCategories = ['Cashback', 'Friends'];
  final List<String> spentCategories = [
    "Shopping",
    "Transport",
    "Food",
    "Clothing",
    "Entertainment",
  ];

  // *** --- Dynamic Data Handling --- ***
  // Assume you have a list of transactions with dates and categories
  List<Transaction> transactions = [
    Transaction(
        date: DateTime(2025, 1, 5), category: "Shopping", amount: 1000.00),
    Transaction(
        date: DateTime(2025, 1, 10), category: "Food", amount: 500.00),
    Transaction(
        date: DateTime(2025, 1, 15), category: "Transport", amount: 200.00),
    Transaction(
        date: DateTime(2025, 1, 20), category: "Cashback", amount: 3000.00),
    Transaction(
        date: DateTime(2025, 2, 1), category: "Shopping", amount: 1200.00),
    Transaction(
        date: DateTime(2025, 2, 8), category: "Entertainment", amount: 300.00),
    Transaction(
        date: DateTime(2025, 2, 15), category: "Friends", amount: 10000.00),
    // ... more transactions for different months and categories
  ];

  Map<String, double> monthlyReceivedSpending = {}; // Will be dynamically calculated
  Map<String, double> monthlySpentSpending = {};   // Will be dynamically calculated
  Map<String, double> dailySpentSpending = {};     // Will be dynamically calculated
  Map<String, double> dailyReceivedSpending = {};   // Will be dynamically calculated

  @override
  void initState() {
    super.initState();
    _updateSpendingData(); // Initial data load
  }

  void _updateSpendingData() {
    monthlySpentSpending = _calculateMonthlySpending(spentCategories);
    monthlyReceivedSpending = _calculateMonthlySpending(receivedCategories);
    dailySpentSpending = _calculateDailySpending(spentCategories);
    dailyReceivedSpending = _calculateDailySpending(receivedCategories);
  }

  Map<String, double> _calculateMonthlySpending(List<String> categories) {
    Map<String, double> spending = {};
    DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    for (String category in categories) {
      double totalAmount = 0;
      for (var transaction in transactions) {
        if (categories.contains(transaction.category) &&
            transaction.category == category &&
            transaction.date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(lastDayOfMonth.add(const Duration(days: 1)))) {
          totalAmount += transaction.amount;
        }
      }
      spending[category] = totalAmount;
    }
    return spending;
  }

  Map<String, double> _calculateDailySpending(List<String> categories) {
    Map<String, double> spending = {};
    DateTime selectedDay = _selectedDate;


    for (String category in categories) {
      double totalAmount = 0;
      for (var transaction in transactions) {
        if (categories.contains(transaction.category) &&
            transaction.category == category &&
            transaction.date.year == selectedDay.year &&
            transaction.date.month == selectedDay.month &&
            transaction.date.day == selectedDay.day) {
          totalAmount += transaction.amount;
        }
      }
      spending[category] = totalAmount;
    }
    return spending;
  }
  // *** --- End Dynamic Data Handling --- ***


  final List<Color> chartColors = [
    const Color(0xFFFFC107),
    const Color(0xFFFF7043),
    const Color(0xFF9575CD),
    const Color(0xFFBA68C8),
    const Color(0xFFFFD54F),
  ];
  final lineChartColor = const Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    Map<String, double> currentSpending =
    _timePeriod == 'Month' ? monthlySpentSpending : dailySpentSpending;
    List<String> currentCategories =
    _chartType == 'Received' ? receivedCategories : spentCategories;

    double totalSpent = _calculateTotalSpending(monthlySpentSpending); // Using monthly for total
    double totalReceived = _calculateTotalSpending(monthlyReceivedSpending); // Using monthly for total

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Spend Analysis',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalSpendReceiveCard(totalSpent, totalReceived, context),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _selectedChartType,
                    underline: const SizedBox(),
                    dropdownColor: Colors.grey.shade50,
                    icon: Icon(LucideIcons.barChart, color: Colors.grey.shade700, size: 16),
                    elevation: 1,
                    hint: Text(_selectedChartType,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                    items: <String>['Pie', 'Bar', 'Line', 'Histogram']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style:
                            TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedChartType = newValue!;
                      });
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.calendar,
                            color: Colors.grey.shade700, size: 16),
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2026),
                          );
                          if (pickedDate != null && pickedDate != _selectedDate) {
                            setState(() {
                              _selectedDate = pickedDate;
                              _updateSpendingData(); // Update data on date change
                            });
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildChartSection(currentSpending, currentCategories),
            const SizedBox(height: 20),
            _buildCategoryStackCard(currentSpending, currentCategories),
            const SizedBox(height: 20),
            _buildStatisticsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSpendReceiveCard(double totalSpent, double totalReceived, BuildContext context) {
    return Card(
      elevation: 2,
      color: Color(0xFF234567),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.arrowDown, color: Colors.redAccent.shade200, size: 20),
                    Text(
                      '${totalSpent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              height: 40,
              child: VerticalDivider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
            Column(
              children: [
                const Text(
                  'Total Received',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.arrowUp, color: Colors.greenAccent.shade200, size: 20),
                    Text(
                      '${totalReceived.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildChartSection(
      Map<String, double> spending, List<String> categories) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildChartByType(_selectedChartType, 'Spend Categories', spending, categories),
      ),
    );
  }

  Widget _buildChartByType(String chartType, String title, Map<String, double> spending, List<String> categories) {
    switch (chartType) {
      case 'Pie':
        return _buildPieChartCard(title, spending, categories);
      case 'Bar':
        return _buildBarChartCard(title, spending, categories);
      case 'Line':
        return _buildLineChartCard(title, spending, categories);
      case 'Histogram':
        return _buildHistogramChartCard(title, spending, categories);
      default:
        return _buildPieChartCard(title, spending, categories);
    }
  }


  Widget _buildPieChartCard(
      String title, Map<String, double> spending, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.pieChart, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(   // Enable touch interaction
                      touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      }
                  ),
                  sections: _generatePieChartSections(spending, categories),
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  centerSpaceColor: Colors.white,
                ),
              ),
            ),
            _touchedIndex != -1 ? // Show category name if a section is touched
            Column(
              children: [
                Text(
                  categories[_touchedIndex], // Category name from touched index
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '€ ${spending[categories[_touchedIndex]]?.toStringAsFixed(2) ?? '0.00'}', // Amount for the category
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ) : Text( // Default text when no section is touched
              '€ 7,500.00', // Static value - consider making dynamic based on total of currentSpending
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          children: _buildPieChartLabels(spending, categories),
        ),
      ],
    );
  }

  Widget _buildBarChartCard(
      String title, Map<String, double> spending, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.barChart, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: _generateBarChartGroups(spending, categories),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: _bottomBarChartTitles(categories),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          children: _buildPieChartLabels(spending, categories),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateBarChartGroups(
      Map<String, double> spending, List<String> categories) {
    return categories.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value;
      double amount = spending[category] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: chartColors[index % chartColors.length],
            width: 20,
          ),
        ],
      );
    }).toList();
  }

  SideTitles _bottomBarChartTitles(List<String> categories) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        final int index = value.toInt();
        if (index >= 0 && index < categories.length) {
          return Text(categories[index],
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10));
        }
        return const Text('');
      },
      interval: 1,
      reservedSize: 30,
    );
  }

  Widget _buildLineChartCard(
      String title, Map<String, double> spending, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.lineChart, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                _generateLineChartBarData(spending, categories)
              ],
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: _bottomLineChartTitles(categories),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles:const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          children: _buildPieChartLabels(spending, categories),
        ),
      ],
    );
  }

  LineChartBarData _generateLineChartBarData(
      Map<String, double> spending, List<String> categories) {
    final List<FlSpot> spots = [];
    categories.asMap().forEach((index, category) {
      spots.add(FlSpot(index.toDouble(), spending[category] ?? 0));
    });

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: lineChartColor,
      barWidth: 2,
      belowBarData: BarAreaData(show: false),
      dotData: const FlDotData(show: true),
    );
  }

  SideTitles _bottomLineChartTitles(List<String> categories) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        final int index = value.toInt();
        if (index >= 0 && index < categories.length) {
          return Text(categories[index],
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
              textAlign: TextAlign.center);
        }
        return const Text('');
      },
      interval: 1,
      reservedSize: 30,
    );
  }

  Widget _buildHistogramChartCard(
      String title, Map<String, double> spending, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: _generateHistogramChartGroups(spending, categories),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: _bottomBarChartTitles(categories),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles:const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData:const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          children: _buildPieChartLabels(spending, categories),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateHistogramChartGroups(
      Map<String, double> spending, List<String> categories) {
    return categories.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value;
      double amount = spending[category] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: chartColors[index % chartColors.length],
            width: 20,
          ),
        ],
      );
    }).toList();
  }

  List<PieChartSectionData> _generatePieChartSections(
      Map<String, double> spending, List<String> categories) {
    double totalSpending = spending.values.reduce((a, b) => a + b);
    return categories.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value;
      final isTouched = index == _touchedIndex; // Check if section is touched
      final radius = isTouched ? 50.0 : 40.0; // Increase radius when touched
      double amount = spending[category] ?? 0;
      double percentage = (amount / totalSpending * 100);
      return PieChartSectionData(
        value: amount,
        color: chartColors[index % chartColors.length],
        radius: radius, // Dynamic radius for animation effect
        showTitle: isTouched ? true : false, // Show title only when touched
        title: '${percentage.toStringAsFixed(1)}%', // Percentage as title
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPieChartLabels(
      Map<String, double> spending, List<String> categories) {
    double totalSpending = spending.values.reduce((a, b) => a + b);
    return categories.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value;
      double amount = spending[category] ?? 0;
      double percentage = (amount / totalSpending * 100);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: chartColors[index % chartColors.length],
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 6),
          ),
          Text(
            '$category ${percentage.toStringAsFixed(0)}%',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(width: 16),
        ],
      );
    }).toList();
  }

  Widget _buildCategoryStackCard(
      Map<String, double> spending, List<String> categories) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCategoryStackContent(spending, categories),
      ),
    );
  }

  Widget _buildCategoryStackContent(Map<String, double> spending, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.list, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Categories',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._buildCategoryStackItems(spending, categories),
      ],
    );
  }


  List<Widget> _buildCategoryStackItems(
      Map<String, double> spending, List<String> categories) {
    final Map<String, IconData> categoryIcons = {
      "Cashback": LucideIcons.dollarSign,
      "Friends": LucideIcons.users,
      "Food": LucideIcons.utensils,
      "Clothing": LucideIcons.shirt,
      "Transport": LucideIcons.car,
      "Entertainment": LucideIcons.tv,
      "Shopping": LucideIcons.shoppingCart,
    };
    return categories.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value;
      double amount = spending[category] ?? 0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 25,
                  decoration: BoxDecoration(
                    color: chartColors[index % chartColors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(right: 12),
                ),
                Icon(categoryIcons[category]!, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
            Text(
              '€${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatisticsCard() {
    List<String> allCategoriesForStatistics = [...spentCategories, ...receivedCategories];

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildStatisticsContent(allCategoriesForStatistics),
      ),
    );
  }

  Widget _buildStatisticsContent(List<String> allCategoriesForStatistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.activity, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            DropdownButton<String>(
              value: _selectedStatisticsCategory,
              items: allCategoriesForStatistics
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(LucideIcons.tag, color: Colors.grey.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(value,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStatisticsCategory = newValue!;
                });
              },
              underline: Container(),
              icon: Icon(LucideIcons.chevronDown,
                  color: Colors.grey.shade700, size: 16),
              elevation: 1,
              dropdownColor: Colors.grey.shade50,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitles(),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _generateLineChartDataForCategory(_selectedStatisticsCategory),
                  isCurved: true,
                  color: lineChartColor,
                  barWidth: 2,
                  belowBarData: BarAreaData(show: false),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  List<FlSpot> _generateLineChartDataForCategory(String category) {
    Map<String, Map<String, double>> timePeriodSpending;

    if (_timePeriod == 'Month') {
      timePeriodSpending = {
        'Spent': monthlySpentSpending,
        'Received': monthlyReceivedSpending,
      };
    } else {
      timePeriodSpending = {
        'Spent': dailySpentSpending,
        'Received': dailyReceivedSpending,
      };
    }

    Map<String, double> currentSpending = timePeriodSpending[_chartType] ?? monthlySpentSpending;

    List<FlSpot> spots = [];
    double categorySpending = currentSpending[category] ?? 0;

    spots = [
      const FlSpot(0, 5 + 0.1 * 5 * 10),
      const FlSpot(1, 10 + 0.1 * 10 * 10),
       FlSpot(2, categorySpending / 4 + 0.1 * 15 * 10),
       FlSpot(3, categorySpending / 3  + 0.1 * 20 * 10),
       FlSpot(4, categorySpending / 2 + 0.1 * 25 * 10),
       FlSpot(5, categorySpending + 0.1 * 30 * 10),
    ];


    return spots;
  }


  List<FlSpot> _generateLineChartData() {
    return [
      const FlSpot(0, 15),
      const FlSpot(1, 22),
      const FlSpot(2, 28),
      const FlSpot(3, 20),
      const FlSpot(4, 25),
      const FlSpot(5, 30),
    ];
  }

  SideTitles _bottomTitles() {
    return SideTitles(
      showTitles: true,
      interval: 1,
      getTitlesWidget: (value, meta) {
        String text = '';
        switch (value.toInt()) {
          case 0:
            text = 'Jan 5';
            break;
          case 1:
            text = 'Jan 10';
            break;
          case 2:
            text = 'Jan 15';
            break;
          case 3:
            text = 'Jan 20';
            break;
          case 4:
            text = 'Jan 25';
            break;
          case 5:
            text = 'Jan 30';
            break;
        }
        return Text(text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 10));
      },
      reservedSize: 22,
    );
  }

  Widget _buildCategorySpendingList(
      Map<String, double> spending, List<String> categories) {
    final Map<String, IconData> categoryIcons = {
      "Cashback": LucideIcons.dollarSign,
      "Friends": LucideIcons.users,
      "Food": LucideIcons.utensils,
      "Clothing": LucideIcons.shirt,
      "Transport": LucideIcons.car,
      "Entertainment": LucideIcons.tv,
      "Shopping": LucideIcons.shoppingCart,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.list, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Spending by Category',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            String category = categories[index];
            double amount = spending[category] ?? 0;
            return _buildCategoryListItem(
                category, amount, categoryIcons[category] ?? LucideIcons.circle);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryListItem(
      String category, double spending, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 12),
              Text(
                category,
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Text(
            '€${spending.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalSpending(Map<String, double> spendingMap) {
    return spendingMap.values.fold(0, (sum, amount) => sum + amount);
  }
}

// *** --- Transaction Data Model --- ***
class Transaction {
  DateTime date;
  String category;
  double amount;

  Transaction({required this.date, required this.category, required this.amount});
}