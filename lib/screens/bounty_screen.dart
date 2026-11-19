import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter & Haptic
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui'; // Untuk efek blur

import '../providers/money_provider.dart';
import '../models/debt.dart';
import '../services/sound_service.dart';

class BountyScreen extends StatefulWidget {
  @override
  _BountyScreenState createState() => _BountyScreenState();
}

class _BountyScreenState extends State<BountyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // 📝 DIALOG TAMBAH KONTRAK (HOLOGRAPHIC)
  void _showAddBountyDialog(BuildContext context) {
    final _nameController = TextEditingController();
    final _amountController = TextEditingController();
    bool _isLent = _tabController.index == 0; 

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
              backgroundColor: Color(0xFF16213E).withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.amber, width: 2)
              ),
              title: Row(
                children: [
                  Icon(Icons.assignment_add, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(child: Text("NEW CONTRACT", style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.amber))),
                ],
              ),
              content: StatefulBuilder(
                builder: (context, setDialogState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Input Nama Target
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          icon: Icon(Icons.person_pin, color: Colors.cyanAccent),
                          hintText: "Target Name",
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    // Input Nominal (Auto Dot)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()], // 👇 Auto Dot Disini
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          icon: Text("Rp", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          hintText: "0",
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Pilihan Tipe
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: _isLent ? Colors.cyanAccent : Colors.redAccent),
                        borderRadius: BorderRadius.circular(10),
                        color: _isLent ? Colors.cyanAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          value: _isLent,
                          dropdownColor: Color(0xFF16213E),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(value: true, child: Text("🎯 ACTIVE BOUNTY (Piutang)", style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: false, child: Text("💀 DEBUFF (Hutang)", style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            setDialogState(() => _isLent = val!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("ABORT", style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.grey))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  icon: Icon(Icons.fingerprint, color: Colors.black),
                  label: Text("SIGN", style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.black)),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;
                    
                    // Bersihkan input sebelum simpan
                    final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
                    
                    final newDebt = DebtModel(
                      name: _nameController.text,
                      amount: amount,
                      dueDate: DateTime.now().add(Duration(days: 7)),
                      isLent: _isLent,
                    );
                    Provider.of<MoneyProvider>(context, listen: false).addDebt(newDebt);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 🌌 Background grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network("https://www.transparenttextures.com/patterns/carbon-fibre.png", repeat: ImageRepeat.repeat),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.amber), onPressed: () => Navigator.pop(context)),
                      Text("BOUNTY BOARD", style: GoogleFonts.pressStart2p(color: Colors.amber, fontSize: 16)),
                      SizedBox(width: 40), // Spacer
                    ],
                  ),
                ),

                // TAB BAR
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10)
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(15)
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: GoogleFonts.blackOpsOne(),
                    tabs: [
                      Tab(text: "TARGETS"),
                      Tab(text: "DEBTS"),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // BODY
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtList(provider, true, currency),  
                      _buildDebtList(provider, false, currency), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        icon: Icon(Icons.add, color: Colors.black, size: 28),
        label: Text("NEW CONTRACT", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
        onPressed: () {
          SoundService.playClick();
          _showAddBountyDialog(context);
        },
      ),
    );
  }

  Widget _buildDebtList(MoneyProvider provider, bool isLent, NumberFormat format) {
    final list = provider.debts.where((d) => d.isLent == isLent).toList();
    
    // Hitung Total Aktif
    double totalValue = list.fold(0, (sum, item) => sum + (item.isPaid ? 0 : item.amount));

    if (list.isEmpty) return _buildEmptyState(isLent);

    return Column(
      children: [
        // 🔹 TOTAL SUMMARY HEADER
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isLent ? [Colors.cyan.shade900, Colors.black] : [Colors.red.shade900, Colors.black]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isLent ? Colors.cyanAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: (isLent ? Colors.cyan : Colors.red).withOpacity(0.2), blurRadius: 15)]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ACTIVE BOUNTY VALUE:", style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12)),
              Text(format.format(totalValue), style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),

        // 🔹 LIST KONTRAK
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 80),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final item = list[i];
              final realIndex = provider.debts.indexOf(item); 
              
              return FadeInUp(
                delay: Duration(milliseconds: i * 100),
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    HapticFeedback.heavyImpact();
                    provider.deleteDebt(realIndex);
                  },
                  background: Container(
                    margin: EdgeInsets.only(bottom: 15),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(15)),
                    child: Icon(Icons.delete_forever, color: Colors.white, size: 32),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      provider.toggleDebtPaid(realIndex); 
                    },
                    child: _buildWantedPoster(item, isLent, format),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 📜 WANTED POSTER CARD
  Widget _buildWantedPoster(DebtModel item, bool isLent, NumberFormat format) {
    Color themeColor = isLent ? Colors.cyanAccent : Colors.redAccent;
    String label = isLent ? "WANTED" : "DEBTOR";
    
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      height: 140,
      child: Stack(
        children: [
          // Background Card
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF0F1526),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.isPaid ? Colors.grey : themeColor, width: 2),
                boxShadow: item.isPaid ? [] : [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 15, offset: Offset(0, 5))]
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                // 1. Mugshot Area
                Container(
                  width: 80, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white12),
                    image: DecorationImage(
                      image: NetworkImage("https://robohash.org/${item.name}.png?set=set1"), // Avatar Robot Unik
                      fit: BoxFit.cover,
                      opacity: item.isPaid ? 0.2 : 1.0
                    )
                  ),
                ),
                SizedBox(width: 15),
                // 2. Info Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: GoogleFonts.blackOpsOne(color: item.isPaid ? Colors.grey : themeColor, fontSize: 18, letterSpacing: 2)),
                      Divider(color: themeColor.withOpacity(0.5), height: 10, thickness: 1),
                      Text(item.name.toUpperCase(), style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("REWARD: ${format.format(item.amount)}", style: GoogleFonts.shareTechMono(color: item.isPaid ? Colors.white24 : Colors.white70)),
                      SizedBox(height: 5),
                      Text("DEADLINE: ${DateFormat('dd MMM yyyy').format(item.dueDate)}", style: GoogleFonts.shareTechMono(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔖 STAMP "COMPLETED" (NEON EFFECT)
          if (item.isPaid)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 4),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 20)]
                      ),
                      child: Text(
                        isLent ? "COLLECTED" : "PAID OFF",
                        style: GoogleFonts.blackOpsOne(color: Colors.greenAccent, fontSize: 24, letterSpacing: 2),
                      ),
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  // 🕵️ STATE KOSONG
  Widget _buildEmptyState(bool isLent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLent ? FontAwesomeIcons.magnifyingGlass : FontAwesomeIcons.shieldHalved,
            size: 80,
            color: Colors.white10
          ),
          SizedBox(height: 20),
          Text(
            isLent ? "NO ACTIVE BOUNTIES" : "NO ACTIVE DEBUFFS",
            style: GoogleFonts.pressStart2p(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// 🔢 FORMATTER ANGKA (Auto Titik)
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