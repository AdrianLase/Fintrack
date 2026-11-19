import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/money_provider.dart';
import '../models/transaction.dart';

class NeonCityScreen extends StatefulWidget {
  @override
  _NeonCityScreenState createState() => _NeonCityScreenState();
}

class _NeonCityScreenState extends State<NeonCityScreen> with SingleTickerProviderStateMixin {
  late AnimationController _gridController;
  final ScrollController _scrollController = ScrollController();

  // Mapping Warna Neon per Kategori
  final Map<String, Color> _categoryColors = {
    'Makanan': Colors.orangeAccent,
    'Transportasi': Colors.cyanAccent,
    'Hiburan': Colors.purpleAccent,
    'Tagihan': Colors.redAccent,
    'Belanja': Colors.pinkAccent,
    'Kesehatan': Colors.greenAccent,
    'Gaji': Colors.blueAccent,
    'Bonus': Colors.tealAccent,
    'Lainnya': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    // Animasi Grid Lantai Bergerak
    _gridController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _gridController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final cityData = _generateCityData(provider.transactions);
    final totalBalance = provider.totalBalance;

    return Scaffold(
      backgroundColor: Color(0xFF050510), // Langit malam sangat gelap
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("NEON CITY VISUALIZER", style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 12)),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 🌌 LAYER 1: BACKGROUND (Stars & Moon)
          Positioned.fill(
            child: CustomPaint(
              painter: StarrySkyPainter(),
            ),
          ),
          
          // 🌕 MOON / SUN (Visualisasi Saldo)
          Positioned(
            top: 100,
            right: 40,
            child: Pulse(
              infinite: true,
              duration: Duration(seconds: 4),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: totalBalance >= 0 
                      ? [Colors.cyanAccent, Colors.blue] 
                      : [Colors.redAccent, Colors.orange],
                    begin: Alignment.topLeft, end: Alignment.bottomRight
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (totalBalance >= 0 ? Colors.cyanAccent : Colors.redAccent).withOpacity(0.6),
                      blurRadius: 40, spreadRadius: 5
                    )
                  ]
                ),
                child: Center(
                  child: Icon(
                    totalBalance >= 0 ? FontAwesomeIcons.buildingColumns : FontAwesomeIcons.biohazard,
                    color: Colors.white, size: 30
                  ),
                ),
              ),
            ),
          ),

          // 🕸️ LAYER 2: RETRO GRID FLOOR (Bergerak)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: AnimatedBuilder(
              animation: _gridController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RetroGridPainter(_gridController.value),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 🏙️ LAYER 3: CITY SKYLINE (Scrollable Buildings)
          Positioned(
            bottom: 80, // Di atas grid sedikit
            left: 0,
            right: 0,
            height: 500, // Tinggi maksimal area gedung
            child: cityData.isEmpty 
              ? Center(child: Text("NO CITY DATA FOUND", style: GoogleFonts.shareTechMono(color: Colors.white24)))
              : ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.4), // Center start
                  itemCount: cityData.length,
                  itemBuilder: (ctx, i) {
                    return _buildBuilding(context, cityData[i], i);
                  },
                ),
          ),

          // 🖥️ LAYER 4: HUD INFO (Bawah)
          Positioned(
            bottom: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10)]
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.white54, size: 15),
                  SizedBox(width: 10),
                  Text("TAP BUILDINGS TO INSPECT", style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 🏗️ LOGIC: Generasi Data Kota
  List<Map<String, dynamic>> _generateCityData(List<TransactionModel> transactions) {
    Map<String, double> categoryTotals = {};
    double maxVal = 0;

    // 1. Grouping
    for (var tx in transactions) {
      if (categoryTotals.containsKey(tx.category)) {
        categoryTotals[tx.category] = categoryTotals[tx.category]! + tx.amount;
      } else {
        categoryTotals[tx.category] = tx.amount;
      }
      // Cari nilai tertinggi untuk skala tinggi gedung
      if (categoryTotals[tx.category]! > maxVal) {
        maxVal = categoryTotals[tx.category]!;
      }
    }

    // 2. Convert to List
    List<Map<String, dynamic>> cityList = [];
    categoryTotals.forEach((key, value) {
      cityList.add({
        'name': key,
        'amount': value,
        'heightRatio': maxVal > 0 ? (value / maxVal) : 0.0,
        'color': _categoryColors[key] ?? Colors.white,
        'isExpense': transactions.firstWhere((t) => t.category == key, orElse: () => TransactionModel(title: '', amount: 0, date: DateTime.now(), isExpense: true, category: '')).isExpense, 
      });
    });

    // Sort: Gedung tinggi di tengah (opsional, biar estetik)
    cityList.sort((a, b) => b['amount'].compareTo(a['amount']));

    return cityList;
  }

  // 🏢 WIDGET: Single Building
  Widget _buildBuilding(BuildContext context, Map<String, dynamic> data, int index) {
    double maxHeight = 350; // Tinggi maksimal gedung dalam pixel
    // FIX 1: Tambahkan casting 'as double'
    double ratio = (data['heightRatio'] as double); 
    double actualHeight = 50 + (ratio * maxHeight); // Min tinggi 50
    
    Color color = data['color'];
    bool isExpense = data['isExpense'];

    return GestureDetector(
      onTap: () => _showBuildingDetails(context, data),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8), // Jarak antar gedung
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Floating Label (Nama Kategori)
            FadeInUp(
              delay: Duration(milliseconds: 500 + (index * 100)),
              child: Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(5)),
                child: Text(
                  data['name'], 
                  style: GoogleFonts.shareTechMono(color: color, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ),

            // THE BUILDING BLOCK
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              tween: Tween<double>(begin: 0, end: actualHeight),
              builder: (context, height, child) {
                return Container(
                  width: 60, // Lebar gedung
                  height: height,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: 2, offset: Offset(0, 0))
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [color.withOpacity(0.6), color.withOpacity(0.0)]
                    )
                  ),
                  child: Stack(
                    children: [
                      // Jendela-jendela (Procedural Windows)
                      _buildWindows(height, color),
                      
                      // Atap Gedung (Antenna)
                      if (!isExpense) 
                        Positioned(top: -15, left: 25, child: Container(width: 2, height: 15, color: color)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindows(double height, Color color) {
    int rows = (height / 15).floor();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(rows, (i) {
        // Acak nyala mati jendela biar organik
        bool lightsOn = (i % 3 != 0); 
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(width: 8, height: 8, color: lightsOn ? color : Colors.black26),
            Container(width: 8, height: 8, color: lightsOn ? color.withOpacity(0.7) : Colors.black26),
          ],
        );
      }),
    );
  }

  // 📊 POPUP DETAIL
  void _showBuildingDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Color(0xFF16213E).withOpacity(0.95),
          border: Border(top: BorderSide(color: data['color'], width: 3)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data['isExpense'] ? FontAwesomeIcons.buildingCircleExclamation : FontAwesomeIcons.buildingCircleCheck, size: 50, color: data['color']),
            SizedBox(height: 15),
            Text("${data['name']} TOWER", style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 22)),
            SizedBox(height: 10),
            Text(
              "Total Volume: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(data['amount'])}",
              style: GoogleFonts.shareTechMono(color: data['color'], fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              data['isExpense'] ? "Warning: High energy consumption detected." : "Status: Generating positive revenue flow.",
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
    );
  }
}

// 🎨 PAINTER 1: RETRO GRID FLOOR
class RetroGridPainter extends CustomPainter {
  final double animationValue;
  RetroGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.3)
      ..strokeWidth = 1;

    final Paint glowPaint = Paint()
      ..color = Colors.purple.withOpacity(0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    // Gambar Garis Vertikal (Perspektif)
    double centerX = size.width / 2;
    for (double i = -10; i <= 10; i++) {
      double xStart = centerX + (i * 40);
      double xEnd = centerX + (i * 150); // Melebar ke bawah (perspektif)
      canvas.drawLine(Offset(xStart, 0), Offset(xEnd, size.height), linePaint);
    }

    // Gambar Garis Horizontal (Bergerak ke bawah)
    double spacing = 40;
    double offset = animationValue * spacing;
    
    for (double y = 0; y < size.height; y += spacing) {
      double currentY = (y + offset) % size.height;
      // Semakin ke bawah semakin tebal (dekat mata)
      linePaint.strokeWidth = 1 + (currentY / size.height * 2);
      linePaint.color = Colors.cyanAccent.withOpacity(0.2 + (currentY / size.height * 0.5)); // Fade in
      
      canvas.drawLine(Offset(0, currentY), Offset(size.width, currentY), linePaint);
    }
    
    // Glow di horizon
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 50), glowPaint);
  }

  @override
  bool shouldRepaint(RetroGridPainter oldDelegate) => true;
}

// 🎨 PAINTER 2: STARRY SKY
class StarrySkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random(42); 

    // FIX 2: Jangan pakai chain, buat paint baru untuk setiap bintang
    for (int i = 0; i < 100; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height * 0.6; 
      double radius = random.nextDouble() * 1.5;
      
      final Paint starPaint = Paint()
        ..color = Colors.white.withOpacity(random.nextDouble());

      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}