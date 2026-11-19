import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/linear_percent_indicator.dart'; // Wajib install percent_indicator
import '../providers/money_provider.dart';

class AchievementsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final badges = provider.allAchievements; 
    
    // Hitung Progress
    int unlockedCount = badges.where((b) => b['unlocked'] == true).length;
    double progress = unlockedCount / badges.length;

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 🌌 Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network("https://www.transparenttextures.com/patterns/cubes.png", repeat: ImageRepeat.repeat),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.amber), 
                        onPressed: () => Navigator.pop(context)
                      ),
                      Expanded(
                        child: Center(
                          child: Text("TROPHY ROOM", style: GoogleFonts.pressStart2p(color: Colors.amber, fontSize: 16)),
                        ),
                      ),
                      SizedBox(width: 40), // Spacer
                    ],
                  ),
                ),

                // 📊 PROGRESS BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("COMPLETION", style: GoogleFonts.shareTechMono(color: Colors.white54)),
                          Text("${(progress * 100).toInt()}%", style: GoogleFonts.blackOpsOne(color: Colors.amber, fontSize: 18)),
                        ],
                      ),
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearPercentIndicator(
                          lineHeight: 12.0,
                          percent: progress,
                          backgroundColor: Colors.white10,
                          progressColor: Colors.amber,
                          animation: true,
                          barRadius: Radius.circular(10),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text("$unlockedCount / ${badges.length} Unlocked", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),

                Divider(color: Colors.white10, height: 30),

                // 🏆 GRID LIST
                Expanded(
                  child: GridView.builder(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75, // Proporsi kartu
                    ),
                    itemCount: badges.length,
                    itemBuilder: (ctx, i) {
                      return _buildAchievementCard(context, badges[i], i);
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

  Widget _buildAchievementCard(BuildContext context, Map<String, dynamic> item, int index) {
    bool isUnlocked = item['unlocked'];
    Color color = isUnlocked ? item['color'] : Colors.grey;
    
    // Efek Glow jika Legendary/Epic
    List<BoxShadow> shadows = [];
    if (isUnlocked && (item['rarity'] == 'LEGENDARY' || item['rarity'] == 'EPIC')) {
      shadows = [BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 1)];
    }

    return FadeInUp(
      delay: Duration(milliseconds: (index % 10) * 50), // Staggered animation
      child: GestureDetector(
        onTap: () => _showCardDetail(context, item),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? color.withOpacity(0.8) : Colors.white10,
              width: isUnlocked ? 2 : 1
            ),
            boxShadow: shadows,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICON
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked ? color.withOpacity(0.15) : Colors.black26,
                ),
                child: Icon(
                  isUnlocked ? item['icon'] : Icons.lock, 
                  size: 24, 
                  color: isUnlocked ? color : Colors.white24
                ),
              ),
              
              SizedBox(height: 10),
              
              // TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  isUnlocked ? item['title'] : "???",
                  style: GoogleFonts.shareTechMono(
                    color: isUnlocked ? Colors.white : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 5),

              // RARITY TAG (FIXED FONT)
              if (isUnlocked)
                Container(
                  margin: EdgeInsets.only(top: 5),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.5), width: 0.5)
                  ),
                  child: Text(
                    item['rarity'],
                    // FIX: Mengganti uMono menjadi shareTechMono
                    style: GoogleFonts.shareTechMono(color: color, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  // 🃏 INTERACTIVE CARD INSPECTION (POPUP)
  void _showCardDetail(BuildContext context, Map<String, dynamic> item) {
    bool isUnlocked = item['unlocked'];
    Color color = isUnlocked ? item['color'] : Colors.grey;

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
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: 300,
                height: 420,
                decoration: BoxDecoration(
                  color: Color(0xFF0F1526).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 40)]
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1, 
                        child: Icon(item['icon'], size: 200, color: color)
                      )
                    ),
                    
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rarity Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))
                          ),
                          child: Text(
                            isUnlocked ? item['rarity'] : "LOCKED",
                            style: GoogleFonts.blackOpsOne(color: Colors.black, fontSize: 12),
                          ),
                        ),
                        
                        Spacer(),
                        
                        // Main Icon
                        ZoomIn(
                          duration: Duration(milliseconds: 500),
                          child: Container(
                            padding: EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.1),
                              border: Border.all(color: color.withOpacity(0.5), width: 2),
                              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)]
                            ),
                            child: Icon(
                              isUnlocked ? item['icon'] : Icons.lock_outline,
                              size: 60,
                              color: color
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Title
                        Text(
                          isUnlocked ? item['title'] : "UNKNOWN",
                          style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Desc
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            isUnlocked ? item['desc'] : "Complete the secret requirement to unlock this trophy.",
                            style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        Spacer(),
                        
                        // Close Btn
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("CLOSE", style: GoogleFonts.pressStart2p(color: Colors.white30, fontSize: 10))
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}