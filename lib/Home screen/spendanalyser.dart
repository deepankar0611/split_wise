import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class SpendAnalyzerScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> categoryData;
  final double amountToPay;
  final double amountToReceive;

  const SpendAnalyzerScreen({
    super.key,
    required this.categoryData,
    required this.amountToPay,
    required this.amountToReceive,
  });

  @override
  State<SpendAnalyzerScreen> createState() => _SpendAnalyzerScreenState();
}

class _SpendAnalyzerScreenState extends State<SpendAnalyzerScreen> {
  String _timePeriod = 'Month';
  String _chartType = 'Spent';
  String _selectedChartType = 'Pie';
  DateTime _selectedDate = DateTime.now();
  String _selectedStatisticsCategory = 'Grocery';
  int _touchedIndex = -1; // Track touched pie section

  // Categories and Icons from HomeScreen
  final List<String> categories = [
    "Grocery",
    "Medicine",
    "Food",
    "Rent",
    "Travel",
    "Shopping",
    "Entertainment",
    "Utilities",
    "Others",
  ];

  final Map<String, Map<String, dynamic>> categoryIcons = {
    "Grocery": {"icon": LucideIcons.shoppingCart, "color": Colors.teal},
    "Medicine": {"icon": LucideIcons.pill, "color": Colors.red},
    "Food": {"icon": LucideIcons.utensils, "color": Colors.orange},
    "Rent": {"icon": LucideIcons.home, "color": Colors.brown},
    "Travel": {"icon": LucideIcons.car, "color": Colors.blueAccent},
    "Shopping": {"icon": LucideIcons.gift, "color": Colors.pinkAccent},
    "Entertainment": {"icon": LucideIcons.film, "color": Colors.purple},
    "Utilities": {"icon": LucideIcons.lightbulb, "color": Colors.blueGrey},
    "Others": {"icon": LucideIcons.circleDollarSign, "color": Colors.grey},
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
    Map<String, double> currentSpending = _getSpendingForTimePeriod(widget.categoryData);

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
            _buildTotalSpendReceiveCard(widget.amountToPay, widget.amountToReceive, context),
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
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
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
                      DropdownButton<String>(
                        value: _timePeriod,
                        underline: const SizedBox(),
                        dropdownColor: Colors.grey.shade50,
                        icon: Icon(LucideIcons.chevronDown, color: Colors.grey.shade700, size: 16),
                        items: <String>['Day', 'Month']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _timePeriod = newValue!;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
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
                            lastDate: DateTime(2025),
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
            _buildChartSection(currentSpending, categories),
            const SizedBox(height: 20),
            _buildCategoryStackCard(currentSpending, categories),
            const SizedBox(height: 20),
            _buildStatisticsCard(widget.categoryData),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getSpendingForTimePeriod(Map<String, Map<String, dynamic>> categoryData) {
    Map<String, double> spending = {};
    for (String category in categories) {
      double totalPaid = categoryData[category]?['totalPaid']?.toDouble() ?? 0.0;
      DateTime? lastInvolved = categoryData[category]?['lastInvolved'] as DateTime?;
      if (_timePeriod == 'Day' && lastInvolved != null) {
        if (lastInvolved.day == _selectedDate.day &&
            lastInvolved.month == _selectedDate.month &&
            lastInvolved.year == _selectedDate.year) {
          spending[category] = totalPaid;
        } else {
          spending[category] = 0.0;
        }
      } else {
        if (lastInvolved != null &&
            lastInvolved.month == _selectedDate.month &&
            lastInvolved.year == _selectedDate.year) {
          spending[category] = totalPaid;
        } else {
          spending[category] = 0.0;
        }
      }
    }
    return spending;
  }

  Widget _buildTotalSpendReceiveCard(double totalSpent, double totalReceived, BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFF234567),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'Total to Pay',
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
                      '₹${totalSpent.toStringAsFixed(2)}',
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
                  'Total to Receive',
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
                      '₹${totalReceived.toStringAsFixed(2)}',
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

  Widget _buildChartSection(Map<String, double> spending, List<String> categories) {
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

  Widget _buildPieChartCard(String title, Map<String, double> spending, List<String> categories) {
    double totalSpending = spending.values.fold(0, (sum, amount) => sum + amount);
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
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: _generatePieChartSections(spending, categories),
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  centerSpaceColor: Colors.white,
                ),
              ),
            ),
            _touchedIndex != -1
                ? Column(
              children: [
                Text(
                  categories[_touchedIndex],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${spending[categories[_touchedIndex]]?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            )
                : Text(
              '₹${totalSpending.toStringAsFixed(2)}',
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

  Widget _buildBarChartCard(String title, Map<String, double> spending, List<String> categories) {
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
                bottomTitles: AxisTitles(sideTitles: _bottomBarChartTitles(categories)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  List<BarChartGroupData> _generateBarChartGroups(Map<String, double> spending, List<String> categories) {
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

  Widget _buildLineChartCard(String title, Map<String, double> spending, List<String> categories) {
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
              lineBarsData: [_generateLineChartBarData(spending, categories)],
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: _bottomLineChartTitles(categories)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  LineChartBarData _generateLineChartBarData(Map<String, double> spending, List<String> categories) {
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

  Widget _buildHistogramChartCard(String title, Map<String, double> spending, List<String> categories) {
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
                bottomTitles: AxisTitles(sideTitles: _bottomBarChartTitles(categories)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  List<BarChartGroupData> _generateHistogramChartGroups(Map<String, double> spending, List<String> categories) {
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

  List<PieChartSectionData> _generatePieChartSections(Map<String, double> spending, List<String> categories) {
    double totalSpending = spending.values.fold(0, (sum, amount) => sum + amount);
    if (totalSpending == 0) return [];
    return categories.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 50.0 : 40.0;
      double amount = spending[category] ?? 0;
      double percentage = (amount / totalSpending * 100);
      return PieChartSectionData(
        value: amount,
        color: chartColors[index % chartColors.length],
        radius: radius,
        showTitle: isTouched,
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPieChartLabels(Map<String, double> spending, List<String> categories) {
    double totalSpending = spending.values.fold(0, (sum, amount) => sum + amount);
    if (totalSpending == 0) return [const Text("No spending data")];
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

  Widget _buildCategoryStackCard(Map<String, double> spending, List<String> categories) {
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

  List<Widget> _buildCategoryStackItems(Map<String, double> spending, List<String> categories) {
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
                Icon(categoryIcons[category]!['icon'] as IconData,
                    color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: const TextStyle(
                      color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            Text(
              '₹${amount.toStringAsFixed(2)}',
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

  Widget _buildStatisticsCard(Map<String, Map<String, dynamic>> categoryData) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildStatisticsContent(categories, categoryData),
      ),
    );
  }

  Widget _buildStatisticsContent(List<String> allCategoriesForStatistics, Map<String, Map<String, dynamic>> categoryData) {
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
              items: allCategoriesForStatistics.map<DropdownMenuItem<String>>((String value) {
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
              icon: Icon(LucideIcons.chevronDown, color: Colors.grey.shade700, size: 16),
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
                bottomTitles: AxisTitles(sideTitles: _bottomTitles()),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _generateLineChartDataForCategory(categoryData),
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

  List<FlSpot> _generateLineChartDataForCategory(Map<String, Map<String, dynamic>> categoryData) {
    List<FlSpot> spots = [];
    double totalPaid = categoryData[_selectedStatisticsCategory]?['totalPaid']?.toDouble() ?? 0.0;
    DateTime? lastInvolved = categoryData[_selectedStatisticsCategory]?['lastInvolved'] as DateTime?;

    if (lastInvolved != null && totalPaid > 0) {
      int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      double dailyAverage = totalPaid / daysInMonth;
      for (int i = 0; i < 6; i++) {
        double x = i * (daysInMonth / 5);
        double y = lastInvolved.day > x ? dailyAverage * (x + 1) : totalPaid;
        spots.add(FlSpot(x, y));
      }
    } else {
      spots = List.generate(6, (index) => FlSpot(index.toDouble(), 0));
    }
    return spots;
  }

  SideTitles _bottomTitles() {
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return SideTitles(
      showTitles: true,
      interval: daysInMonth / 5,
      getTitlesWidget: (value, meta) {
        int day = value.toInt() + 1;
        if (day <= daysInMonth) {
          return Text('Day $day',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 10));
        }
        return const Text('');
      },
      reservedSize: 22,
    );
  }
}