import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart'; 

import '../providers/money_provider.dart';
import '../models/transaction.dart';
import '../services/sound_service.dart';
import 'transaction_selector_screen.dart'; 
import 'stats_screen.dart';
import 'bounty_screen.dart';
import 'shield_screen.dart';
import 'achievements_screen.dart';
import 'raid_boss_screen.dart';
import 'neon_city_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  // 🗺️ MAPPING ICON UNTUK AUTO-FARM
  final Map<String, IconData> _farmingIcons = {
    'Listrik / Token': Icons.electric_bolt_rounded,
    'Air PDAM': Icons.water_drop_rounded,
    'Kuota Internet': Icons.signal_cellular_alt_rounded,
    'WiFi / Indihome': Icons.router_rounded,
    'Laundry': Icons.local_laundry_service_rounded,
    'Tagihan Lainnya': FontAwesomeIcons.fileInvoiceDollar,
  };

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Animasi Background Bernafas
    _breathingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _checkLevelUp() {
    _confettiController.play();
  }

  // 📸 FITUR GANTI FOTO
  Future<void> _pickProfileImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      Provider.of<MoneyProvider>(context, listen: false).updateProfileImage(pickedFile.path);
      SoundService.playClick();
    }
  }

  void _showProfilePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF0F1526).withOpacity(0.95),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: Colors.amber.withOpacity(0.5))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("UPDATE AVATAR", style: GoogleFonts.pressStart2p(color: Colors.amber, fontSize: 12)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerBtn(Icons.camera_alt, "CAMERA", Colors.cyanAccent, () {
                  Navigator.pop(ctx);
                  _pickProfileImage(context, ImageSource.camera);
                }),
                _buildPickerBtn(Icons.image, "GALLERY", Colors.purpleAccent, () {
                  Navigator.pop(ctx);
                  _pickProfileImage(context, ImageSource.gallery);
                }),
              ],
            )
          ],
        ),
      )
    );
  }

  Widget _buildPickerBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1), border: Border.all(color: color)),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 10),
          Text(label, style: GoogleFonts.shareTechMono(color: Colors.white))
        ],
      ),
    );
  }

  // 📝 FITUR GANTI NAMA (IDENTITY PROTOCOL)
  void _showChangeNameDialog(BuildContext context, String currentName) {
    final _nameController = TextEditingController(text: currentName);
    
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.amber, width: 2)),
              title: Row(
                children: [
                  Icon(Icons.badge, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(child: Text("IDENTITY PROTOCOL", style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.amber))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ENTER NEW DESIGNATION:", style: GoogleFonts.shareTechMono(color: Colors.white54)),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.amber.withOpacity(0.5))
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.edit, color: Colors.white24)
                      ),
                      autofocus: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: GoogleFonts.pressStart2p(color: Colors.grey, fontSize: 10))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      Provider.of<MoneyProvider>(context, listen: false).updateUserName(_nameController.text);
                      SoundService.playClick();
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text("CONFIRM", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // 🌾 AUTO-FARM CONSOLE
  void _showAutoFarmConsole(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildBottomSheetUI(context, provider),
    );
  }

  // 🔢 INPUT DIALOG (AUTO FARM)
  void _showAmountInputDialog(BuildContext context, String title) {
    final _amountController = TextEditingController();
    
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
              backgroundColor: Color(0xFF0F1526).withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
                side: BorderSide(color: Colors.greenAccent, width: 2)
              ),
              title: Row(
                children: [
                  Pulse(infinite: true, child: Icon(Icons.terminal, color: Colors.greenAccent)),
                  SizedBox(width: 10),
                  Expanded(child: Text("EXECUTE PAYMENT", style: GoogleFonts.pressStart2p(color: Colors.greenAccent, fontSize: 10))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Target Resource: $title", style: GoogleFonts.shareTechMono(color: Colors.greenAccent.withOpacity(0.7))),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 10)]
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: GoogleFonts.vt323(color: Colors.white, fontSize: 35),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("> Rp ", style: GoogleFonts.vt323(color: Colors.greenAccent, fontSize: 35)),
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text("ABORT", style: GoogleFonts.pressStart2p(color: Colors.redAccent, fontSize: 10))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent, 
                    shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    elevation: 10,
                    shadowColor: Colors.greenAccent
                  ),
                  onPressed: () {
                    if (_amountController.text.isEmpty) return;
                    double amount = double.parse(_amountController.text.replaceAll('.', ''));
                    Provider.of<MoneyProvider>(context, listen: false).triggerAutoFarm(title, amount, "Tagihan");
                    Navigator.pop(ctx); 
                    _checkLevelUp();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("✅ SYSTEM: Payment Protocol Executed for $title"), 
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }, 
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("CONFIRM", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
                  )
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
    final moneyProvider = Provider.of<MoneyProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final today = DateTime.now();
    final todayTransactions = moneyProvider.transactions.where((tx) => 
      tx.date.day == today.day && 
      tx.date.month == today.month && 
      tx.date.year == today.year
    ).toList();

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E), 
      body: Stack(
        children: [
          // 🌌 LAYER 0: ANIMATED BACKGROUND
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                   Positioned(
                    top: -50, right: -50,
                    child: Transform.scale(
                      scale: _breathingAnimation.value,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(0.15), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.4), blurRadius: 80, spreadRadius: 10)]),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100, left: -50,
                    child: Transform.scale(
                      scale: _breathingAnimation.value,
                      child: Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.15), boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 80, spreadRadius: 10)]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 📱 LAYER 1: MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // 🔹 Header & Menu
                _buildHeader(moneyProvider),
                
                SizedBox(height: 10),
                
                // 💳 Holographic Balance Card
                _buildHoloCard(moneyProvider, currencyFormat),
                
                // 🔮 Oracle Terminal
                _buildOracleTerminal(moneyProvider),

                SizedBox(height: 15),

                // 🔹 Quest Log Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.cyanAccent, size: 14),
                          SizedBox(width: 8),
                          Text("DAILY LOG [TODAY]", style: GoogleFonts.pressStart2p(color: Colors.cyanAccent, fontSize: 10)),
                        ],
                      ),
                      GestureDetector(
                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatsScreen())),
                         child: Container(
                           padding: EdgeInsets.all(5),
                           decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                           child: Icon(Icons.bar_chart, color: Colors.cyanAccent, size: 16)
                         )
                      )
                    ],
                  ),
                ),
                
                // 🔹 Transaction List
                Expanded(
                  child: todayTransactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(20, 15, 20, 80), 
                          itemCount: todayTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = todayTransactions.reversed.toList()[index];
                            final originalIndex = moneyProvider.transactions.indexOf(tx);
                            return _buildTransactionItem(tx, moneyProvider, originalIndex, currencyFormat, index);
                          },
                        ),
                ),
              ],
            ),
          ),

          // 🎉 Confetti Layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5, minBlastForce: 2,
              emissionFrequency: 0.05, numberOfParticles: 20, gravity: 0.2,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
            ),
          ),
        ],
      ),
      
      // 🔘 FAB: NEW QUEST
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          SoundService.playClick();
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => TransactionSelectorScreen()) 
          );
          _checkLevelUp();
        },
        backgroundColor: Colors.amber,
        elevation: 10,
        icon: Icon(Icons.gamepad_rounded, color: Colors.black), 
        label: Text("NEW QUEST", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
      ),
    );
  }

  // ✨ WIDGETS & COMPONENTS ✨

  Widget _buildHeader(MoneyProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          Row(
            children: [
              // 📸 AVATAR (Klik untuk ganti foto)
              GestureDetector(
                onTap: () => _showProfilePicker(context),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 55, height: 55, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withOpacity(0.2))),
                    Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 2)),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.deepPurple,
                        backgroundImage: provider.profileImage != null ? FileImage(File(provider.profileImage!)) : null,
                        child: provider.profileImage == null ? Icon(Icons.face_retouching_natural, color: Colors.white) : null,
                      ),
                    ),
                    Positioned(bottom: 0, right: 0, child: Container(padding: EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: Icon(Icons.edit, size: 8, color: Colors.black)))
                  ],
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✏️ NAMA USER (Klik untuk ganti nama)
                    GestureDetector(
                      onTap: () => _showChangeNameDialog(context, provider.userName),
                      child: Row(
                        children: [
                          Flexible(child: Text(provider.userName.toUpperCase(), style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 18), overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 8),
                          Icon(Icons.edit_note, color: Colors.white24, size: 16)
                        ],
                      ),
                    ),
                    SizedBox(height: 2),
                    // RANK
                    Text(provider.userRank, style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearPercentIndicator(lineHeight: 6.0, percent: provider.levelProgress, backgroundColor: Colors.white12, progressColor: Colors.amber, padding: EdgeInsets.zero, barRadius: Radius.circular(10), animation: true)),
                    SizedBox(height: 4),
                    Text("${provider.currentXP} XP / 500 XP", style: GoogleFonts.poppins(fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // BUTTON SCROLL
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(color: Color(0xFF16213E).withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Row(
                children: [
                  // 🏙️ NEON CITY
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _BouncingButton(
                      icon: Icons.location_city_rounded,
                      label: "City",
                      color: Colors.purpleAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NeonCityScreen()))
                    ),
                  ),
                  // 👾 RAID BOSS
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _BouncingButton(
                      icon: FontAwesomeIcons.dragon, 
                      label: "Raid", 
                      color: Colors.redAccent, 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RaidBossScreen()))
                    ),
                  ),
                  // 🛡️ SHIELD
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _BouncingButton(
                      icon: Icons.shield_outlined, 
                      label: "Shields", 
                      color: Colors.cyanAccent, 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShieldScreen()))
                    ),
                  ),
                  // 📜 BOUNTIES
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _BouncingButton(
                      icon: Icons.assignment_ind_rounded, 
                      label: "Bounties", 
                      color: Colors.orangeAccent, 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BountyScreen()))
                    ),
                  ),
                  // 🌾 AUTO-FARM
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _BouncingButton(
                      icon: Icons.agriculture_rounded, 
                      label: "Auto-Farm", 
                      color: Colors.greenAccent, 
                      onTap: () => _showAutoFarmConsole(context)
                    ),
                  ),
                  // 🏆 AWARDS
                  _BouncingButton(
                    icon: Icons.emoji_events_rounded, 
                    label: "Awards", 
                    color: Colors.amberAccent, 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen()))
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOracleTerminal(MoneyProvider provider) {
    if (provider.isStealthMode) return SizedBox.shrink();

    return FadeInUp(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: provider.oracleColor.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: provider.oracleColor.withOpacity(0.1), blurRadius: 10)]
        ),
        child: Row(
          children: [
            Pulse(infinite: true, child: Icon(Icons.remove_red_eye_rounded, color: provider.oracleColor, size: 20)),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ORACLE PREDICTION", style: GoogleFonts.shareTechMono(color: provider.oracleColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(provider.oracleMessage, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHoloCard(MoneyProvider provider, NumberFormat currency) {
    return ZoomIn(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        height: 200, width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(colors: [Color(0xFFE94560).withOpacity(0.8), Color(0xFF0F3460).withOpacity(0.9)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: Color(0xFFE94560).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))], border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned(bottom: 0, left: 0, right: 0, height: 80, child: Opacity(opacity: 0.3, child: LineChart(LineChartData(gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: provider.transactions.take(7).toList().asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(), isCurved: true, color: Colors.white, barWidth: 3, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.white.withOpacity(0.3)))],),),),),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("TOTAL LOOT", style: GoogleFonts.pressStart2p(color: Colors.white70, fontSize: 10)), GestureDetector(onTap: () => provider.toggleStealthMode(), child: Icon(provider.isStealthMode ? Icons.visibility_off : Icons.visibility, color: Colors.white30))]),
                      Spacer(),
                      Text(provider.isStealthMode ? "Rp *********" : currency.format(provider.totalBalance), style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 32)),
                      Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statRow(Icons.arrow_downward, "IN", provider.totalIncome, Colors.greenAccent),
                          Container(width: 1, height: 20, color: Colors.white24),
                          _statRow(Icons.arrow_upward, "OUT", provider.totalExpense, Colors.orangeAccent),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, String label, double val, Color color) {
    return Row(children: [Icon(icon, color: color, size: 16), SizedBox(width: 5), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)), Text(NumberFormat.compact().format(val), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white))])]);
  }

  Widget _buildTransactionItem(TransactionModel tx, MoneyProvider provider, int index, NumberFormat format, int animIndex) {
    return Dismissible(
      key: UniqueKey(), direction: DismissDirection.endToStart, onDismissed: (_) => provider.deleteTransaction(index),
      background: Container(margin: EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(15)), alignment: Alignment.centerRight, padding: EdgeInsets.only(right: 20), child: Icon(Icons.delete_forever, color: Colors.white, size: 30)),
      child: FadeInUp(duration: Duration(milliseconds: 500), delay: Duration(milliseconds: animIndex * 100), child: Container(margin: EdgeInsets.only(bottom: 12), padding: EdgeInsets.all(15), decoration: BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Row(children: [Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: _getColor(tx.category).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: FaIcon(_getIcon(tx.category), color: _getColor(tx.category), size: 18)), SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tx.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), Text(DateFormat('HH:mm').format(tx.date), style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11))])), Text((tx.isExpense ? "- " : "+ ") + (provider.isStealthMode ? "***" : format.format(tx.amount)), style: GoogleFonts.poppins(color: tx.isExpense ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold))]))),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sunny, size: 80, color: Colors.white12), SizedBox(height: 10), Text("NO QUESTS TODAY", style: GoogleFonts.pressStart2p(color: Colors.white24, fontSize: 10))]));
  }

  // 🛠️ BUILDER UNTUK BOTTOM SHEET (NEW DESIGN)
  Widget _buildBottomSheetUI(BuildContext context, MoneyProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(25), height: 550,
          decoration: BoxDecoration(
            color: Color(0xFF0F1526).withOpacity(0.9), 
            border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 1),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 20)]
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 5)])),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hub, color: Colors.greenAccent),
                  SizedBox(width: 10),
                  Text("AUTO-FARM TERMINAL", style: GoogleFonts.pressStart2p(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
              Divider(color: Colors.greenAccent.withOpacity(0.3), height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.6),
                  itemCount: provider.farmingTargets.length,
                  itemBuilder: (ctx, i) {
                    String label = provider.farmingTargets[i];
                    IconData icon = _farmingIcons[label] ?? Icons.help_outline;
                    
                    return FadeInUp(
                      delay: Duration(milliseconds: i * 100),
                      child: _AutoFarmButton(
                        label: label, 
                        icon: icon, 
                        onTap: () {
                          Navigator.pop(context);
                          _showAmountInputDialog(context, label);
                        }
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Makanan': return Colors.orange;
      case 'Transportasi': return Colors.blue;
      case 'Hiburan': return Colors.purple;
      case 'Gaji': return Colors.green;
      case 'Tagihan': return Colors.pink;
      default: return Colors.teal;
    }
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Makanan': return FontAwesomeIcons.burger;
      case 'Transportasi': return FontAwesomeIcons.shuttleSpace;
      case 'Hiburan': return FontAwesomeIcons.gamepad;
      case 'Gaji': return FontAwesomeIcons.coins;
      case 'Tagihan': return FontAwesomeIcons.fileInvoiceDollar;
      default: return FontAwesomeIcons.ghost;
    }
  }
}

// 🎮 BOUNCY BUTTON WITH SOUND 🔊
class _BouncingButton extends StatefulWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _BouncingButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override __BouncingButtonState createState() => __BouncingButtonState();
}

class __BouncingButtonState extends State<_BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _scaleAnimation;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 100)); _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  
  @override Widget build(BuildContext context) { 
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        SoundService.playClick();
      }, 
      onTapUp: (_) { 
        _controller.reverse(); 
        widget.onTap(); 
      }, 
      onTapCancel: () => _controller.reverse(), 
      child: ScaleTransition(
        scale: _scaleAnimation, 
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12), 
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(15), 
                border: Border.all(color: widget.color.withOpacity(0.3)), 
                boxShadow: [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 10)]
              ), 
              child: Icon(widget.icon, color: widget.color, size: 24)
            ), 
            SizedBox(height: 6), 
            Text(widget.label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600))
          ]
        )
      )
    ); 
  }
}

// 🌾 AUTO-FARM BUTTON WITH SOUND 🔊
class _AutoFarmButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AutoFarmButton({required this.label, required this.icon, required this.onTap});

  @override
  __AutoFarmButtonState createState() => __AutoFarmButtonState();
}

class __AutoFarmButtonState extends State<_AutoFarmButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 50));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        SoundService.playClick();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF0F1526),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.4), width: 1),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent.withOpacity(0.1)),
                child: Icon(widget.icon, color: Colors.greenAccent, size: 24)
              ),
              SizedBox(height: 8),
              Text(
                widget.label, 
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔢 FORMATTER RUPIAH (Auto Titik untuk Auto Farm)
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