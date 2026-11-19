import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/money_provider.dart';
import '../models/transaction.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int touchedIndex = -1; 
  bool isShowExpense = true; 
  String timeFilter = 'Month'; // Options: 'Day', 'Month', 'All'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // 1. FILTER DATA (LOGIC INTI)
    final now = DateTime.now();
    List<TransactionModel> filteredTx = provider.transactions.where((tx) {
      // Filter Expense/Income
      if (tx.isExpense != isShowExpense) return false;

      // Filter Waktu
      if (timeFilter == 'Day') {
        return tx.date.day == now.day && tx.date.month == now.month && tx.date.year == now.year;
      } else if (timeFilter == 'Month') {
        return tx.date.month == now.month && tx.date.year == now.year;
      }
      return true; // All Time
    }).toList();

    // 2. Hitung Total
    double totalAmount = filteredTx.fold(0, (sum, item) => sum + item.amount);
    
    // 3. Grouping Kategori (Untuk Pie Chart)
    Map<String, double> categoryMap = {};
    for (var tx in filteredTx) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
    }
    var sortedEntries = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // 4. Data Harian (Untuk Bar Chart - Khusus Mode Month)
    Map<int, double> dailyMap = {};
    if (timeFilter == 'Month') {
      for (var tx in filteredTx) {
        dailyMap[tx.date.day] = (dailyMap[tx.date.day] ?? 0) + tx.amount;
      }
    }

    // Insight Data
    String topCategory = sortedEntries.isNotEmpty ? sortedEntries.first.key : "-";
    double avgDaily = totalAmount / (timeFilter == 'Day' ? 1 : (timeFilter == 'Month' ? now.day : 30));

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("ANALYTICS COMMAND", style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 12)),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            // 🎛️ 1. CONTROL PANEL (Type & Time)
            _buildControlPanel(),
            
            SizedBox(height: 25),

            // 💰 2. TOTAL SUMMARY
            FadeInDown(
              child: Column(
                children: [
                  Text(
                    isShowExpense ? "TOTAL DAMAGE DEALT" : "TOTAL LOOT GAINED",
                    style: GoogleFonts.shareTechMono(color: Colors.white54, letterSpacing: 2),
                  ),
                  SizedBox(height: 5),
                  Text(
                    currencyFormat.format(totalAmount),
                    style: GoogleFonts.blackOpsOne(
                      color: isShowExpense ? Colors.redAccent : Colors.greenAccent, 
                      fontSize: 32,
                      shadows: [BoxShadow(color: (isShowExpense ? Colors.red : Colors.green).withOpacity(0.5), blurRadius: 20)]
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            // 📊 3. DYNAMIC CHART (Bar Chart jika Month, Pie Chart jika lainnya)
            if (timeFilter == 'Month' && dailyMap.isNotEmpty) ...[
               Text("DAILY ACTIVITY TREND", style: GoogleFonts.pressStart2p(color: Colors.white38, fontSize: 10)),
               SizedBox(height: 20),
               Container(
                 height: 200,
                 padding: EdgeInsets.all(10),
                 child: BarChart(
                   BarChartData(
                     alignment: BarChartAlignment.spaceAround,
                     maxY: dailyMap.values.isEmpty ? 0 : dailyMap.values.reduce(max) * 1.2,
                     barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          // FIX: Menghapus getTooltipColor untuk menghindari error versi
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'Tgl ${group.x.toInt()}\n',
                              GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                              children: [TextSpan(text: NumberFormat.compact().format(rod.toY), style: TextStyle(color: Colors.cyanAccent))]
                            );
                          }
                        ),
                     ),
                     titlesData: FlTitlesData(
                       show: true,
                       bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Text(val.toInt() % 5 == 0 ? val.toInt().toString() : '', style: TextStyle(color: Colors.white38, fontSize: 10)))),
                       leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     ),
                     gridData: FlGridData(show: false),
                     borderData: FlBorderData(show: false),
                     barGroups: dailyMap.entries.map((e) => BarChartGroupData(
                       x: e.key,
                       barRods: [
                         BarChartRodData(
                           toY: e.value,
                           color: isShowExpense ? Colors.redAccent : Colors.greenAccent,
                           width: 6,
                           borderRadius: BorderRadius.circular(4),
                           backDrawRodData: BackgroundBarChartRodData(show: true, toY: dailyMap.values.reduce(max) * 1.2, color: Colors.white.withOpacity(0.05))
                         )
                       ]
                     )).toList(),
                   )
                 ),
               ),
               SizedBox(height: 30),
            ] else ...[
               // PIE CHART DEFAULT
               SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: (isShowExpense ? Colors.redAccent : Colors.greenAccent).withOpacity(0.1), blurRadius: 60, spreadRadius: 5)]),
                    ),
                    sortedEntries.isEmpty 
                    ? _buildEmptyChart()
                    : PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: _generateChartSections(sortedEntries, totalAmount),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],

            // 📊 4. INSIGHT GRID
            if (sortedEntries.isNotEmpty)
              FadeInUp(
                duration: Duration(milliseconds: 600),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard("TOP SOURCE", topCategory, FontAwesomeIcons.crown, Colors.amber)),
                    SizedBox(width: 15),
                    Expanded(child: _buildStatCard("DAILY AVG", currencyFormat.format(avgDaily), Icons.speed, Colors.cyanAccent)),
                  ],
                ),
              ),

            SizedBox(height: 30),

            // 📜 5. DETAILED LIST
            Row(
              children: [
                Icon(Icons.segment, color: Colors.white54, size: 16),
                SizedBox(width: 10),
                Text("BREAKDOWN (${timeFilter.toUpperCase()})", style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 10)),
              ],
            ),
            SizedBox(height: 15),

            if (filteredTx.isEmpty) 
              Center(child: Padding(padding: EdgeInsets.all(20), child: Text("NO DATA DETECTED", style: GoogleFonts.shareTechMono(color: Colors.white24))))
            else
              ...List.generate(sortedEntries.length, (index) {
                final entry = sortedEntries[index];
                return _buildListItem(entry, totalAmount, index, currencyFormat);
              }),
          ],
        ),
      ),
    );
  }

  // 🎛️ CONTROL PANEL WIDGET
  Widget _buildControlPanel() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFF0F1526),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Row 1: Expense / Income Toggle
          Row(
            children: [
              Expanded(child: _buildTabBtn("DAMAGE", true, Colors.redAccent)),
              SizedBox(width: 10),
              Expanded(child: _buildTabBtn("LOOT", false, Colors.greenAccent)),
            ],
          ),
          SizedBox(height: 15),
          // Row 2: Time Filter (Day / Month / All)
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildTimeBtn("DAY", 'Day'),
                _buildTimeBtn("MONTH", 'Month'),
                _buildTimeBtn("ALL", 'All'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeBtn(String label, String value) {
    bool isSelected = timeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { timeFilter = value; touchedIndex = -1; }),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label, 
              style: GoogleFonts.shareTechMono(
                color: isSelected ? Colors.cyanAccent : Colors.white38, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, bool isExp, Color color) {
    bool isSelected = isShowExpense == isExp;
    return GestureDetector(
      onTap: () => setState(() { isShowExpense = isExp; touchedIndex = -1; }),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.white10),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)] : []
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.blackOpsOne(color: isSelected ? color : Colors.white24, fontSize: 14),
          ),
        ),
      ),
    );
  }

  // 📊 WIDGET: STAT CARD
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 10),
          Text(title, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
          SizedBox(height: 2),
          Text(value, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // 📝 LIST ITEM
  Widget _buildListItem(MapEntry<String, double> entry, double total, int index, NumberFormat format) {
    double percentage = entry.value / total;
    Color color = _getColor(entry.key);

    return FadeInLeft(
      delay: Duration(milliseconds: index * 100),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color(0xFF16213E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: FaIcon(_getCategoryIcon(entry.key), color: color, size: 18),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(format.format(entry.value), style: GoogleFonts.shareTechMono(color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutExpo,
                        height: 6,
                        width: (MediaQuery.of(context).size.width - 100) * percentage, 
                        decoration: BoxDecoration(
                          color: color, 
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🥧 PIE CHART SECTIONS
  List<PieChartSectionData> _generateChartSections(List<MapEntry<String, double>> data, double total) {
    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (data[i].value / total) * 100;
      
      return PieChartSectionData(
        color: _getColor(data[i].key),
        value: data[i].value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: GoogleFonts.shareTechMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        borderSide: isTouched ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
      );
    });
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 50, color: Colors.white10),
          SizedBox(height: 10),
          Text("NO DATA", style: GoogleFonts.shareTechMono(color: Colors.white24)),
        ],
      ),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Makanan': return Color(0xFFFF9F1C);
      case 'Transportasi': return Color(0xFF2EC4B6);
      case 'Hiburan': return Color(0xFFE71D36);
      case 'Tagihan': return Color(0xFFF72585);
      case 'Belanja': return Color(0xFF7209B7);
      case 'Kesehatan': return Color(0xFF4361EE);
      case 'Gaji': return Color(0xFF00FF9D);
      case 'Uang Bulanan': return Colors.cyanAccent;
      case 'Bonus': return Color(0xFF00B8D4);
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan': return FontAwesomeIcons.burger;
      case 'Transportasi': return FontAwesomeIcons.shuttleSpace;
      case 'Hiburan': return FontAwesomeIcons.gamepad;
      case 'Tagihan': return FontAwesomeIcons.fileInvoiceDollar;
      case 'Belanja': return FontAwesomeIcons.bagShopping;
      case 'Kesehatan': return FontAwesomeIcons.heartPulse;
      case 'Gaji': return FontAwesomeIcons.moneyBillWave;
      case 'Uang Bulanan': return FontAwesomeIcons.calendarCheck;
      case 'Bonus': return FontAwesomeIcons.gem;
      default: return FontAwesomeIcons.circleQuestion;
    }
  }
}