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

  final List<String> receivedCategories = ['Cashback', 'Friends'];
  final List<String> spentCategories = [
    "Shopping",
    "Transport",
    "Food",
    "Clothing",
    "Entertainment",
  ];

  Map<String, double> monthlyReceivedSpending = {
    "Cashback": 35309.50,
    "Friends": 15000.00,
  };

  Map<String, double> monthlySpentSpending = {
    "Shopping": 21185.7,
    "Transport": 5000.00,
    "Food": 19773.32,
    "Clothing": 7061.9,
    "Entertainment": 1412.38,
  };
  Map<String, double> dailySpentSpending = {
    "Shopping": 706.19,
    "Transport": 150.00,
    "Food": 659.11,
    "Clothing": 235.39,
    "Entertainment": 47.08,
  };
  Map<String, double> dailyReceivedSpending = {
    "Cashback": 1176.98,
    "Friends": 500.00,
  };

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

    double totalSpent = _calculateTotalSpending(monthlySpentSpending);
    double totalReceived = _calculateTotalSpending(monthlyReceivedSpending);

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
            _buildTotalSpendReceiveCard(totalSpent, totalReceived), // Total Spend/Receive Card
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _selectedChartType,
                    underline: const SizedBox(),
                    dropdownColor: Colors.grey.shade50,
                    icon: Icon(LucideIcons.chevronDown, color: Colors.grey.shade700, size: 16),
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
                        DateFormat('MMM yyyy').format(_selectedDate),
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

  Widget _buildTotalSpendReceiveCard(double totalSpent, double totalReceived) {
    return Card(
      elevation: 1,
      color: Colors.white,
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
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  '€${totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  '€${totalReceived.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
    switch (_selectedChartType) {
      case 'Pie':
        return _buildPieChartCard('Spend Categories', spending, categories);
      case 'Bar':
        return _buildBarChartCard('Spend Categories', spending, categories);
      case 'Line':
        return _buildLineChartCard('Spend Categories', spending, categories);
      case 'Histogram':
        return _buildHistogramChartCard('Spend Categories', spending, categories);
      default:
        return _buildPieChartCard('Spend Categories', spending, categories);
    }
  }

  Widget _buildPieChartCard(
      String title, Map<String, double> spending, List<String> categories) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieChartSections(spending, categories),
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      centerSpaceColor: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '€ 7,500.00',
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
        ),
      ),
    );
  }

  Widget _buildBarChartCard(
      String title, Map<String, double> spending, List<String> categories) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
        ),
      ),
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
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
        ),
      ),
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
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
        ),
      ),
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
      double amount = spending[category] ?? 0;
      double percentage = (amount / totalSpending * 100);
      return PieChartSectionData(
        value: amount,
        color: chartColors[index % chartColors.length],
        radius: 40,
        showTitle: false,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildCategoryStackItems(spending, categories),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryStackItems(
      Map<String, double> spending, List<String> categories) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedStatisticsCategory,
                  items: allCategoriesForStatistics
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
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
        ),
      ),
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
        Text(
          'Spending by Category',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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