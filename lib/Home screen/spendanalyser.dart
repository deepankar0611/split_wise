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
  String _timePeriod = 'Month'; // Options: 'Day', 'Month', 'Custom Range', 'Multi-Month'
  String _selectedChartType = 'Pie';
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customDateRange;
  List<DateTime> _selectedMonths = [DateTime.now()];
  String _selectedStatisticsCategory = 'Grocery';
  int _touchedIndex = -1;

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

  final lineChartColor = const Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
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
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalSpendReceiveCard(widget.amountToPay, widget.amountToReceive, context),
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _selectedChartType,
                    underline: const SizedBox(),
                    dropdownColor: Colors.grey.shade50,
                    icon: Icon(LucideIcons.barChart, color: Colors.grey.shade700, size: screenSize.width * 0.04),
                    elevation: 1,
                    hint: Text(_selectedChartType, style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.035)),
                    items: <String>['Pie', 'Bar', 'Line'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.035)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedChartType = newValue!;
                      });
                    },
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DropdownButton<String>(
                          value: _timePeriod,
                          underline: const SizedBox(),
                          dropdownColor: Colors.grey.shade50,
                          icon: Icon(LucideIcons.chevronDown, color: Colors.grey.shade700, size: screenSize.width * 0.04),
                          items: <String>['Day', 'Month', 'Custom Range', 'Multi-Month'].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.035)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _timePeriod = newValue!;
                              if (_timePeriod == 'Custom Range') {
                                _showDateRangePicker(context);
                              } else if (_timePeriod == 'Multi-Month') {
                                _showMultiMonthPicker(context);
                              }
                            });
                          },
                        ),
                        SizedBox(width: screenSize.width * 0.02),
                        _buildDateFilterDisplay(screenSize),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildChartSection(currentSpending, categories, screenSize),
            SizedBox(height: screenSize.height * 0.02),
            _buildCategoryStackCard(currentSpending, categories, screenSize),
            SizedBox(height: screenSize.height * 0.02),
            _buildStatisticsCard(widget.categoryData, screenSize),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterDisplay(Size screenSize) {
    if (_timePeriod == 'Custom Range' && _customDateRange != null) {
      return Row(
        children: [
          Text(
            '${DateFormat('yyyy-MM-dd').format(_customDateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_customDateRange!.end)}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.035),
          ),
          IconButton(
            icon: Icon(LucideIcons.calendar, color: Colors.grey.shade700, size: screenSize.width * 0.04),
            onPressed: () => _showDateRangePicker(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    } else if (_timePeriod == 'Multi-Month' && _selectedMonths.isNotEmpty) {
      return Row(
        children: [
          Text(
            '${_selectedMonths.length} Months',
            style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.035),
          ),
          IconButton(
            icon: Icon(LucideIcons.calendar, color: Colors.grey.shade700, size: screenSize.width * 0.04),
            onPressed: () => _showMultiMonthPicker(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Text(
            DateFormat('yyyy-MM-dd').format(_selectedDate),
            style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.035),
          ),
          IconButton(
            icon: Icon(LucideIcons.calendar, color: Colors.grey.shade700, size: screenSize.width * 0.04),
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
      );
    }
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (pickedRange != null) {
      setState(() {
        _customDateRange = pickedRange;
      });
    }
  }

  void _showMultiMonthPicker(BuildContext context) async {
    final List<DateTime> pickedMonths = await showDialog(
      context: context,
      builder: (context) => MultiMonthPicker(
        initialMonths: _selectedMonths,
        firstDate: DateTime(2000),
        lastDate: DateTime(2025),
      ),
    ) ?? _selectedMonths;
    setState(() {
      _selectedMonths = pickedMonths;
    });
  }

  Map<String, double> _getSpendingForTimePeriod(Map<String, Map<String, dynamic>> categoryData) {
    print('Category Data: $categoryData'); // Debug input data
    Map<String, double> spending = {};
    for (String category in categories) {
      double averageAmount = categoryData[category]?['averageAmount']?.toDouble() ?? 0.0;
      DateTime? lastInvolved = categoryData[category]?['lastInvolved'] as DateTime?;
      print('$category - Average: $averageAmount, Last Involved: $lastInvolved'); // Debug each category

      // Default to showing average amount
      spending[category] = averageAmount;

      if (lastInvolved != null) {
        switch (_timePeriod) {
          case 'Day':
            if (lastInvolved.day != _selectedDate.day ||
                lastInvolved.month != _selectedDate.month ||
                lastInvolved.year != _selectedDate.year) {
              spending[category] = 0.0;
            }
            break;
          case 'Month':
            if (lastInvolved.month != _selectedDate.month || lastInvolved.year != _selectedDate.year) {
              spending[category] = 0.0;
            }
            break;
          case 'Custom Range':
            if (_customDateRange != null &&
                (lastInvolved.isBefore(_customDateRange!.start) ||
                    lastInvolved.isAfter(_customDateRange!.end.add(const Duration(days: 1))))) {
              spending[category] = 0.0;
            }
            break;
          case 'Multi-Month':
            bool inSelectedMonths = _selectedMonths.any((month) =>
            lastInvolved.month == month.month && lastInvolved.year == month.year);
            if (!inSelectedMonths) {
              spending[category] = 0.0;
            }
            break;
        }
      }
    }
    print('Filtered Spending: $spending'); // Debug output
    return spending;
  }

  Widget _buildTotalSpendReceiveCard(double totalSpent, double totalReceived, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Card(
      elevation: 2,
      color: const Color(0xFF234567),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'Total to Pay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.035,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.arrowDown, color: Colors.redAccent.shade200, size: screenSize.width * 0.05),
                    Text(
                      '₹${totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              height: screenSize.height * 0.05,
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.02),
              child: VerticalDivider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
            Column(
              children: [
                Text(
                  'Total to Receive',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.035,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.arrowUp, color: Colors.greenAccent.shade200, size: screenSize.width * 0.05),
                    Text(
                      '₹${totalReceived.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.width * 0.05,
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

  Widget _buildChartSection(Map<String, double> spending, List<String> categories, Size screenSize) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: _buildChartByType(_selectedChartType, 'Spend Categories', spending, categories, screenSize),
      ),
    );
  }

  Widget _buildChartByType(String chartType, String title, Map<String, double> spending, List<String> categories, Size screenSize) {
    switch (chartType) {
      case 'Pie':
        return _buildPieChartCard(title, spending, categories, screenSize);
      case 'Bar':
        return _buildBarChartCard(title, spending, categories, screenSize);
      case 'Line':
        return _buildLineChartCard(title, spending, categories, screenSize);
      default:
        return _buildPieChartCard(title, spending, categories, screenSize);
    }
  }

  Widget _buildPieChartCard(String title, Map<String, double> spending, List<String> categories, Size screenSize) {
    double totalSpending = spending.values.fold(0, (sum, amount) => sum + amount);
    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<String> sortedCategories = sortedEntries.map((e) => e.key).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.pieChart, color: Colors.grey.shade700, size: screenSize.width * 0.05),
            SizedBox(width: screenSize.width * 0.02),
            Text(
              title,
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: screenSize.height * 0.015),
        AspectRatio(
          aspectRatio: 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: _generatePieChartSections(spending, categories),
                  sectionsSpace: 0,
                  centerSpaceRadius: screenSize.width * 0.15,
                  centerSpaceColor: Colors.white,
                ),
              ),
              _touchedIndex != -1
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sortedCategories[_touchedIndex],
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: screenSize.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${spending[sortedCategories[_touchedIndex]]?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                ],
              )
                  : Text(
                '₹${totalSpending.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: screenSize.width * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenSize.height * 0.015),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: screenSize.width * 0.04,
          runSpacing: screenSize.height * 0.01,
          children: _buildPieChartLabels(spending, categories, screenSize),
        ),
      ],
    );
  }

  Widget _buildBarChartCard(String title, Map<String, double> spending, List<String> categories, Size screenSize) {
    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<String> sortedCategories = sortedEntries.map((e) => e.key).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.barChart, color: Colors.grey.shade700, size: screenSize.width * 0.05),
            SizedBox(width: screenSize.width * 0.02),
            Text(
              title,
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: screenSize.height * 0.015),
        AspectRatio(
          aspectRatio: 1.5,
          child: BarChart(
            BarChartData(
              barGroups: _generateBarChartGroups(spending, categories),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: _bottomBarChartTitles(sortedCategories, screenSize)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        SizedBox(height: screenSize.height * 0.015),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: screenSize.width * 0.04,
          runSpacing: screenSize.height * 0.01,
          children: _buildPieChartLabels(spending, categories, screenSize),
        ),
      ],
    );
  }

  Widget _buildLineChartCard(String title, Map<String, double> spending, List<String> categories, Size screenSize) {
    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<String> sortedCategories = sortedEntries.map((e) => e.key).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.lineChart, color: Colors.grey.shade700, size: screenSize.width * 0.05),
            SizedBox(width: screenSize.width * 0.02),
            Text(
              title,
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: screenSize.height * 0.015),
        AspectRatio(
          aspectRatio: 1.5,
          child: LineChart(
            LineChartData(
              lineBarsData: [_generateLineChartBarData(spending, sortedCategories)],
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: _bottomLineChartTitles(sortedCategories, screenSize)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        SizedBox(height: screenSize.height * 0.015),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: screenSize.width * 0.04,
          runSpacing: screenSize.height * 0.01,
          children: _buildPieChartLabels(spending, categories, screenSize),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generatePieChartSections(Map<String, double> spending, List<String> categories) {
    double totalSpending = spending.values.fold(0, (sum, amount) => sum + amount);
    if (totalSpending == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey,
          radius: MediaQuery.of(context).size.width * 0.1,
          title: 'No Data',
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        )
      ];
    }

    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value.key;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? MediaQuery.of(context).size.width * 0.12 : MediaQuery.of(context).size.width * 0.1;
      double amount = entry.value.value;
      double percentage = (amount / totalSpending * 100);
      return PieChartSectionData(
        value: amount,
        color: categoryIcons[category]!['color'] as Color,
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

  List<BarChartGroupData> _generateBarChartGroups(Map<String, double> spending, List<String> categories) {
    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sortedEntries.isEmpty || sortedEntries.every((entry) => entry.value == 0)) {
      return [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(toY: 1, color: Colors.grey, width: MediaQuery.of(context).size.width * 0.05),
          ],
        )
      ];
    }

    return sortedEntries.asMap().entries.map((entry) {
      int index = entry.key;
      String category = entry.value.key;
      double amount = entry.value.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: categoryIcons[category]!['color'] as Color,
            width: MediaQuery.of(context).size.width * 0.05,
          ),
        ],
      );
    }).toList();
  }

  SideTitles _bottomBarChartTitles(List<String> sortedCategories, Size screenSize) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        final int index = value.toInt();
        if (index >= 0 && index < sortedCategories.length) {
          return Text(
            sortedCategories[index],
            style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.025),
            textAlign: TextAlign.center,
          );
        }
        return const Text('');
      },
      interval: 1,
      reservedSize: screenSize.height * 0.03,
    );
  }

  LineChartBarData _generateLineChartBarData(Map<String, double> spending, List<String> sortedCategories) {
    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sortedEntries.isEmpty || sortedEntries.every((entry) => entry.value == 0)) {
      return LineChartBarData(
        spots: [const FlSpot(0, 0)],
        color: Colors.grey,
        barWidth: 2,
        dotData: FlDotData(show: false),
      );
    }

    final List<FlSpot> spots = sortedEntries.asMap().entries.map((entry) {
      int index = entry.key;
      return FlSpot(index.toDouble(), entry.value.value);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: lineChartColor,
      barWidth: 2,
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          String category = sortedCategories[index];
          return FlDotCirclePainter(
            radius: MediaQuery.of(context).size.width * 0.01,
            color: categoryIcons[category]!['color'] as Color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
    );
  }

  SideTitles _bottomLineChartTitles(List<String> sortedCategories, Size screenSize) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        final int index = value.toInt();
        if (index >= 0 && index < sortedCategories.length) {
          return Text(
            sortedCategories[index],
            style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.025),
            textAlign: TextAlign.center,
          );
        }
        return const Text('');
      },
      interval: 1,
      reservedSize: screenSize.height * 0.04,
    );
  }

  List<Widget> _buildPieChartLabels(Map<String, double> spending, List<String> categories, Size screenSize) {
    double totalSpending = spending.values.fold(0, (sum, amount) => sum + amount);
    if (totalSpending == 0) return [const Text("No spending data")];

    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      String category = entry.value.key;
      double amount = entry.value.value;
      double percentage = (amount / totalSpending * 100);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenSize.width * 0.02,
            height: screenSize.width * 0.02,
            decoration: BoxDecoration(
              color: categoryIcons[category]!['color'] as Color,
              shape: BoxShape.circle,
            ),
            margin: EdgeInsets.only(right: screenSize.width * 0.015),
          ),
          Text(
            '$category ${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: categoryIcons[category]!['color'] as Color,
              fontSize: screenSize.width * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
        ],
      );
    }).toList();
  }

  Widget _buildCategoryStackCard(Map<String, double> spending, List<String> categories, Size screenSize) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: _buildCategoryStackContent(spending, categories, screenSize),
      ),
    );
  }

  Widget _buildCategoryStackContent(Map<String, double> spending, List<String> categories, Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.list, color: Colors.grey.shade700, size: screenSize.width * 0.05),
            SizedBox(width: screenSize.width * 0.02),
            Text(
              'Categories',
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: screenSize.height * 0.015),
        ..._buildCategoryStackItems(spending, categories, screenSize),
      ],
    );
  }

  List<Widget> _buildCategoryStackItems(Map<String, double> spending, List<String> categories, Size screenSize) {
    var sortedEntries = spending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      String category = entry.key;
      double amount = entry.value;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: screenSize.width * 0.025,
                  height: screenSize.height * 0.035,
                  decoration: BoxDecoration(
                    color: categoryIcons[category]!['color'] as Color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: EdgeInsets.only(right: screenSize.width * 0.03),
                ),
                Icon(categoryIcons[category]!['icon'] as IconData, color: Colors.grey.shade700, size: screenSize.width * 0.05),
                SizedBox(width: screenSize.width * 0.03),
                Text(
                  category,
                  style: TextStyle(
                    color: categoryIcons[category]!['color'] as Color,
                    fontSize: screenSize.width * 0.037,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: screenSize.width * 0.037,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatisticsCard(Map<String, Map<String, dynamic>> categoryData, Size screenSize) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: _buildStatisticsContent(categories, categoryData, screenSize),
      ),
    );
  }

  Widget _buildStatisticsContent(List<String> allCategoriesForStatistics, Map<String, Map<String, dynamic>> categoryData, Size screenSize) {
    Color categoryColor = categoryIcons[_selectedStatisticsCategory]!['color'] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.activity, color: Colors.grey.shade700, size: screenSize.width * 0.05),
                SizedBox(width: screenSize.width * 0.02),
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
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
                      Icon(LucideIcons.tag, color: Colors.grey.shade700, size: screenSize.width * 0.04),
                      SizedBox(width: screenSize.width * 0.02),
                      Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.035)),
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
              icon: Icon(LucideIcons.chevronDown, color: Colors.grey.shade700, size: screenSize.width * 0.04),
              elevation: 1,
              dropdownColor: Colors.grey.shade50,
            ),
          ],
        ),
        SizedBox(height: screenSize.height * 0.015),
        AspectRatio(
          aspectRatio: 1.5,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: _bottomTitles(screenSize)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _generateLineChartDataForCategory(categoryData),
                  isCurved: true,
                  color: categoryColor,
                  barWidth: 2,
                  belowBarData: BarAreaData(show: false),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: screenSize.width * 0.01,
                      color: categoryColor,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                  ),
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
    double averageAmount = categoryData[_selectedStatisticsCategory]?['averageAmount']?.toDouble() ?? 0.0;
    DateTime? lastInvolved = categoryData[_selectedStatisticsCategory]?['lastInvolved'] as DateTime?;

    if (_timePeriod == 'Custom Range' && _customDateRange != null) {
      int daysInRange = _customDateRange!.end.difference(_customDateRange!.start).inDays + 1;
      double dailyAverage = averageAmount / daysInRange;
      for (int i = 0; i < 6; i++) {
        double x = i * (daysInRange / 5);
        double y = lastInvolved != null && lastInvolved.isAfter(_customDateRange!.start.add(Duration(days: x.toInt())))
            ? dailyAverage * (x + 1)
            : averageAmount;
        spots.add(FlSpot(x, y));
      }
    } else if (_timePeriod == 'Multi-Month' && _selectedMonths.isNotEmpty) {
      int totalMonths = _selectedMonths.length;
      double monthlyAverage = averageAmount / totalMonths;
      for (int i = 0; i < totalMonths && i < 6; i++) {
        spots.add(FlSpot(i.toDouble(), monthlyAverage * (i + 1)));
      }
    } else {
      int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      double dailyAverage = averageAmount / daysInMonth;
      for (int i = 0; i < 6; i++) {
        double x = i * (daysInMonth / 5);
        double y = lastInvolved != null && lastInvolved.day > x ? dailyAverage * (x + 1) : averageAmount;
        spots.add(FlSpot(x, y));
      }
    }
    return spots.isEmpty ? List.generate(6, (index) => FlSpot(index.toDouble(), 0)) : spots;
  }

  SideTitles _bottomTitles(Size screenSize) {
    if (_timePeriod == 'Custom Range' && _customDateRange != null) {
      int daysInRange = _customDateRange!.end.difference(_customDateRange!.start).inDays + 1;
      return SideTitles(
        showTitles: true,
        interval: daysInRange / 5,
        getTitlesWidget: (value, meta) {
          int dayOffset = value.toInt();
          DateTime date = _customDateRange!.start.add(Duration(days: dayOffset));
          return Text(
            DateFormat('MM-dd').format(date),
            style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.025),
          );
        },
        reservedSize: screenSize.height * 0.03,
      );
    } else if (_timePeriod == 'Multi-Month' && _selectedMonths.isNotEmpty) {
      return SideTitles(
        showTitles: true,
        interval: 1,
        getTitlesWidget: (value, meta) {
          int index = value.toInt();
          if (index >= 0 && index < _selectedMonths.length) {
            return Text(
              DateFormat('MMM yyyy').format(_selectedMonths[index]),
              style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.025),
            );
          }
          return const Text('');
        },
        reservedSize: screenSize.height * 0.03,
      );
    } else {
      int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      return SideTitles(
        showTitles: true,
        interval: daysInMonth / 5,
        getTitlesWidget: (value, meta) {
          int day = value.toInt() + 1;
          if (day <= daysInMonth) {
            return Text(
              'Day $day',
              style: TextStyle(color: Colors.grey.shade700, fontSize: screenSize.width * 0.025),
            );
          }
          return const Text('');
        },
        reservedSize: screenSize.height * 0.03,
      );
    }
  }
}

class MultiMonthPicker extends StatefulWidget {
  final List<DateTime> initialMonths;
  final DateTime firstDate;
  final DateTime lastDate;

  const MultiMonthPicker({
    super.key,
    required this.initialMonths,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<MultiMonthPicker> createState() => _MultiMonthPickerState();
}

class _MultiMonthPickerState extends State<MultiMonthPicker> {
  late List<DateTime> _selectedMonths;

  @override
  void initState() {
    super.initState();
    _selectedMonths = List.from(widget.initialMonths);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Months'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: (widget.lastDate.year - widget.firstDate.year + 1) * 12,
          itemBuilder: (context, index) {
            final year = widget.firstDate.year + (index ~/ 12);
            final month = (index % 12) + 1;
            final date = DateTime(year, month);
            if (date.isAfter(widget.lastDate)) return const SizedBox.shrink();
            final isSelected = _selectedMonths.any((d) => d.year == year && d.month == month);

            return CheckboxListTile(
              title: Text(DateFormat('MMMM yyyy').format(date)),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedMonths.add(date);
                  } else {
                    _selectedMonths.removeWhere((d) => d.year == year && d.month == month);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, widget.initialMonths),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedMonths),
          child: const Text('OK'),
        ),
      ],
    );
  }
}