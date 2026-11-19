import 'dart:math';
import 'dart:ui'; // Untuk ImageFilter (Blur)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter & Haptic
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../providers/money_provider.dart';
import '../services/sound_service.dart';

class RaidBossScreen extends StatefulWidget {
  @override
  _RaidBossScreenState createState() => _RaidBossScreenState();
}

class _RaidBossScreenState extends State<RaidBossScreen> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    // 1. Animasi Getar (Shake) saat diserang
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    
    // Tween untuk getar (0 -> 10 -> 0)
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // 2. Animasi Bernapas (Breathing) untuk Boss (Idle)
    _breathingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact(); // Getar Fisik HP
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final boss = provider.activeRaid;

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 🌌 Background Red Glow (Danger Zone)
          Positioned(
            top: -100, left: -50,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.1),
                boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 100, spreadRadius: 10)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // APP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.redAccent, size: 18)
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text("RAID BATTLE", style: GoogleFonts.pressStart2p(color: Colors.redAccent, fontSize: 16)),
                      SizedBox(width: 40), // Dummy spacer
                    ],
                  ),
                ),

                Expanded(
                  child: boss == null 
                    ? _buildSummonForm(context) 
                    : _buildBattleArena(context, boss, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 TAMPILAN SUMMON (FORM INPUT)
  Widget _buildSummonForm(BuildContext context) {
    final _nameController = TextEditingController();
    final _hpController = TextEditingController();

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Pulse(
              infinite: true,
              child: Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 50)]
                ),
                child: Icon(FontAwesomeIcons.dungeon, size: 60, color: Colors.redAccent),
              ),
            ),
            SizedBox(height: 30),
            Text("NO TARGET LOCKED", style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 24)),
            Text("Summon a saving goal to destroy!", style: GoogleFonts.shareTechMono(color: Colors.white54)),
            SizedBox(height: 40),
            
            _buildCyberInput(_nameController, "TARGET NAME", Icons.api),
            SizedBox(height: 20),
            _buildCyberInput(_hpController, "TOTAL PRICE (HP)", Icons.monetization_on, isNumber: true),
            
            SizedBox(height: 40),
            
            GestureDetector(
              onTap: () {
                if (_nameController.text.isNotEmpty && _hpController.text.isNotEmpty) {
                  double hp = double.parse(_hpController.text.replaceAll('.', ''));
                  Provider.of<MoneyProvider>(context, listen: false).summonBoss(_nameController.text, hp);
                  HapticFeedback.heavyImpact();
                  SoundService.playClick();
                }
              },
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 20, offset: Offset(0,5))]
                ),
                child: Center(
                  child: Text("SUMMON BOSS", style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 18, letterSpacing: 2)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ⚔️ TAMPILAN BATTLE ARENA
  Widget _buildBattleArena(BuildContext context, Map boss, MoneyProvider provider) {
    double maxHp = boss['max_hp'];
    double currentHp = boss['current_hp'];
    double progress = (currentHp / maxHp).clamp(0.0, 1.0);
    bool isDead = currentHp <= 0;
    
    // Icon Boss Berdasarkan Harga
    IconData bossIcon = FontAwesomeIcons.spider;
    if (maxHp > 1000000) bossIcon = FontAwesomeIcons.ghost;
    if (maxHp > 10000000) bossIcon = FontAwesomeIcons.dragon;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 20),
          
          // 1. BOSS VISUAL (SHAKE + BREATHE)
          // FIX: Menggabungkan Controller agar animasi berjalan bersamaan
          AnimatedBuilder(
            animation: Listenable.merge([_shakeController, _breathingController]),
            builder: (ctx, child) {
              double breatheScale = 1.0 + (_breathingController.value * 0.05); // Skala 1.0 - 1.05
              double shakeOffset = sin(_shakeAnimation.value * pi) * 10;
              
              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: Transform.scale(
                  scale: breatheScale,
                  child: Container(
                    height: 220, width: 220,
                    decoration: BoxDecoration(
                      color: isDead ? Colors.grey.withOpacity(0.1) : Colors.red.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDead ? Colors.grey : Colors.redAccent, width: 2),
                      boxShadow: [
                        BoxShadow(color: (isDead ? Colors.grey : Colors.redAccent).withOpacity(0.3), blurRadius: 50, spreadRadius: 5),
                        // FIX: Menghapus inset: true yang menyebabkan error
                      ]
                    ),
                    child: Center(
                      child: isDead 
                        ? Icon(FontAwesomeIcons.skull, size: 80, color: Colors.grey)
                        : Icon(bossIcon, size: 80, color: Colors.redAccent),
                    ),
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 30),
          
          // 2. BOSS STATS PANEL
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF0F1526).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10)
            ),
            child: Column(
              children: [
                Text(isDead ? "ENEMY DEFEATED" : boss['name'].toUpperCase(), style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 14)),
                SizedBox(height: 5),
                Text(isDead ? "LOOT SECURED" : "THREAT LEVEL ${boss['level']}", style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 12)),
                SizedBox(height: 20),
                
                // HP Bar
                Stack(
                  children: [
                    Container(height: 20, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10))),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOutExpo,
                      width: (MediaQuery.of(context).size.width - 80) * progress,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red.shade900, Colors.redAccent]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.6), blurRadius: 10)]
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${(progress * 100).toInt()}% HP", style: GoogleFonts.shareTechMono(color: Colors.white54)),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(currentHp),
                      style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontWeight: FontWeight.bold)
                    ),
                  ],
                )
              ],
            ),
          ),

          SizedBox(height: 30),

          // 3. ACTION GRID
          if (!isDead) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    label: "ATTACK", 
                    subLabel: "Save Money",
                    color: Colors.redAccent, 
                    icon: FontAwesomeIcons.khanda, 
                    onTap: () => _showAttackDialog(context)
                  )
                ),
                SizedBox(width: 15),
                Expanded(
                  flex: 1,
                  child: _buildActionButton(
                    label: "FLEE", 
                    subLabel: "Give Up",
                    color: Colors.grey, 
                    icon: FontAwesomeIcons.personRunning, 
                    onTap: () => provider.retreatBoss()
                  )
                ),
              ],
            )
          ] else ...[
             GestureDetector(
               onTap: () {
                 HapticFeedback.mediumImpact();
                 provider.retreatBoss();
               },
               child: Container(
                 width: double.infinity,
                 height: 70,
                 decoration: BoxDecoration(
                   gradient: LinearGradient(colors: [Colors.green, Colors.greenAccent]),
                   borderRadius: BorderRadius.circular(15),
                   boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 20)]
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.check_circle, color: Colors.black),
                     SizedBox(width: 10),
                     Text("CLAIM VICTORY", style: GoogleFonts.blackOpsOne(color: Colors.black, fontSize: 18)),
                   ],
                 ),
               ),
             )
          ],
        ],
      ),
    );
  }

  // 📝 CUSTOM INPUT FIELD
  Widget _buildCyberInput(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 10)),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF0F1526),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumber ? [CurrencyInputFormatter()] : [], // AUTO DOT
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.redAccent),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              hintText: "...",
              hintStyle: TextStyle(color: Colors.white24)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String label, required String subLabel, required Color color, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        SoundService.playClick();
        onTap();
      },
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(label, style: GoogleFonts.blackOpsOne(color: color, fontSize: 16)),
            Text(subLabel, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // 💥 ATTACK DIALOG
  void _showAttackDialog(BuildContext context) {
    final _damageController = TextEditingController();
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.redAccent, width: 2)),
              title: Row(
                children: [
                  Icon(FontAwesomeIcons.burst, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text("DEAL DAMAGE", style: GoogleFonts.pressStart2p(color: Colors.redAccent, fontSize: 12)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Enter amount to save:", style: GoogleFonts.shareTechMono(color: Colors.white70)),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5))
                    ),
                    child: TextField(
                      controller: _damageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()], // AUTO DOT
                      style: GoogleFonts.vt323(fontSize: 35, color: Colors.white),
                      decoration: InputDecoration(
                        prefixText: "> ", 
                        prefixStyle: TextStyle(color: Colors.redAccent, fontSize: 35),
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text("RETREAT", style: GoogleFonts.pressStart2p(color: Colors.white38, fontSize: 10))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    elevation: 10
                  ),
                  onPressed: () {
                    if (_damageController.text.isNotEmpty) {
                      // Hapus titik sebelum proses
                      double dmg = double.parse(_damageController.text.replaceAll('.', ''));
                      Provider.of<MoneyProvider>(context, listen: false).attackBoss(dmg);
                      
                      Navigator.pop(ctx);
                      _triggerShake(); // Panggil efek getar layar utama
                      
                      // Sound FX
                      SoundService.playExpense(); 

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("💥 CRITICAL HIT! Rp ${NumberFormat.decimalPattern('id').format(dmg)} SAVED!"), 
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("ATTACK!", style: GoogleFonts.blackOpsOne(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
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