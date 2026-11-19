import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter & Haptic
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui'; // Untuk Blur effect

import '../providers/money_provider.dart';
import '../services/sound_service.dart';

class ShieldScreen extends StatelessWidget {
  final List<String> categories = [
    'Makanan', 'Transportasi', 'Hiburan', 'Belanja', 'Tagihan', 'Kesehatan', 'Lainnya'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 🌌 Background Ambient Glow
          Positioned(
            top: -100, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withOpacity(0.1),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 100, spreadRadius: 10)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 🛡️ HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent, size: 18)
                        ), 
                        onPressed: () => Navigator.pop(context)
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("SHIELD PROTOCOL", style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 14)),
                            SizedBox(height: 5),
                            Text("PROTECT YOUR ASSETS", style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                          ],
                        ),
                      ),
                      SizedBox(width: 40), // Spacer balancing
                    ],
                  ),
                ),

                // 📜 SHIELD LIST
                Expanded(
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      final limit = provider.getCategoryBudget(cat);
                      final used = provider.getCategoryExpense(cat);
                      
                      // Logic Warna & Progress
                      double progress = 0.0;
                      if (limit > 0) progress = (used / limit);
                      
                      Color shieldColor = Colors.cyanAccent; // Aman
                      String status = "STABLE";
                      IconData statusIcon = Icons.shield_moon;

                      if (limit == 0) {
                        shieldColor = Colors.grey;
                        status = "OFFLINE";
                        statusIcon = Icons.power_off;
                      } else if (progress >= 1.0) {
                        shieldColor = Colors.redAccent; // Jebol
                        status = "BREACHED";
                        statusIcon = Icons.warning_amber_rounded;
                      } else if (progress > 0.7) {
                        shieldColor = Colors.orangeAccent; // Bahaya
                        status = "CRITICAL";
                        statusIcon = Icons.bolt;
                      }

                      return FadeInUp(
                        delay: Duration(milliseconds: i * 100),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            SoundService.playClick();
                            _showSetBudgetDialog(context, cat, limit);
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Stack(
                              children: [
                                // Glow effect di belakang kartu jika critical/breached
                                if (progress > 0.7)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [BoxShadow(color: shieldColor.withOpacity(0.3), blurRadius: 20)],
                                      ),
                                    ),
                                  ),
                                
                                // Main Card
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF16213E).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: shieldColor.withOpacity(0.5), width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      // Row Atas: Icon & Nama
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: shieldColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: shieldColor.withOpacity(0.3))
                                            ),
                                            child: FaIcon(_getIcon(cat), color: shieldColor, size: 18),
                                          ),
                                          SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(cat.toUpperCase(), style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                Row(
                                                  children: [
                                                    Icon(statusIcon, color: shieldColor, size: 10),
                                                    SizedBox(width: 5),
                                                    Text(status, style: GoogleFonts.pressStart2p(color: shieldColor, fontSize: 8)),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          // Edit Icon
                                          Icon(Icons.edit, color: Colors.white24, size: 16)
                                        ],
                                      ),
                                      
                                      SizedBox(height: 15),
                                      
                                      // Progress Bar & Angka
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("INTEGRITY", style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
                                              Text(
                                                limit > 0 ? "${((1 - progress.clamp(0.0, 1.0)) * 100).toInt()}%" : "0%",
                                                style: GoogleFonts.blackOpsOne(color: shieldColor, fontSize: 14)
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          // Bar Container
                                          Stack(
                                            children: [
                                              Container(
                                                height: 8,
                                                width: double.infinity,
                                                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                                              ),
                                              AnimatedContainer(
                                                duration: Duration(milliseconds: 1000),
                                                curve: Curves.easeOutExpo,
                                                height: 8,
                                                width: MediaQuery.of(context).size.width * (progress > 1 ? 1 : progress),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: [shieldColor.withOpacity(0.5), shieldColor]),
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: [BoxShadow(color: shieldColor, blurRadius: 6, spreadRadius: 1)]
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("DAMAGE: ${currency.format(used)}", style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 11)),
                                              Text(
                                                limit > 0 ? "MAX: ${currency.format(limit)}" : "NOT SET",
                                                style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 11)
                                              ),
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔢 DIALOG SET BUDGET (Holographic + Auto Dot)
  void _showSetBudgetDialog(BuildContext context, String category, double currentLimit) {
    // Format awal jika sudah ada limit
    final formatter = NumberFormat('#,###', 'id_ID');
    String initialText = currentLimit > 0 ? formatter.format(currentLimit) : '';
    final controller = TextEditingController(text: initialText);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              backgroundColor: Color(0xFF0F1526).withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
                side: BorderSide(color: Colors.cyanAccent, width: 2)
              ),
              title: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Expanded(child: Text("SHIELD CONFIG", style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.cyanAccent))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MODULE: $category", style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 20),
                  Text("MAX CAPACITY (Rp)", style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 10)),
                  SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10)]
                    ),
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      // 👇 FORMATTER OTOMATIS
                      inputFormatters: [CurrencyInputFormatter()],
                      style: GoogleFonts.vt323(color: Colors.white, fontSize: 35),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("> ", style: GoogleFonts.vt323(color: Colors.cyanAccent, fontSize: 35)),
                        ),
                        border: InputBorder.none,
                        hintText: "0",
                        hintStyle: TextStyle(color: Colors.white24)
                      ),
                      autofocus: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text("CANCEL", style: GoogleFonts.pressStart2p(color: Colors.redAccent, fontSize: 10))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    elevation: 10,
                    shadowColor: Colors.cyanAccent
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (controller.text.isNotEmpty) {
                      // Hapus titik sebelum simpan
                      double val = double.parse(controller.text.replaceAll(RegExp(r'[^0-9]'), ''));
                      Provider.of<MoneyProvider>(context, listen: false).setCategoryBudget(category, val);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("ACTIVATE", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Makanan': return FontAwesomeIcons.burger;
      case 'Transportasi': return FontAwesomeIcons.shuttleSpace;
      case 'Hiburan': return FontAwesomeIcons.gamepad;
      case 'Tagihan': return FontAwesomeIcons.fileInvoiceDollar;
      case 'Belanja': return FontAwesomeIcons.bagShopping;
      case 'Kesehatan': return FontAwesomeIcons.heartPulse;
      default: return FontAwesomeIcons.ghost;
    }
  }
}

// 🔢 FORMATTER ANGKA (Reuse Class)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    int value = int.tryParse(cleanText) ?? 0;
    final formatter = NumberFormat('#,###', 'id_ID');
    String newText = formatter.format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}