import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Haptic & InputFormatter
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart'; // Wajib untuk format angka
import 'package:image_picker/image_picker.dart'; // Wajib untuk kamera/galeri
import 'dart:math';

import '../providers/money_provider.dart';
import '../models/transaction.dart';
import '../services/sound_service.dart';
import '../services/ocr_service.dart'; // Pastikan file ini ada

class TransactionSelectorScreen extends StatefulWidget {
  @override
  _TransactionSelectorScreenState createState() => _TransactionSelectorScreenState();
}

class _TransactionSelectorScreenState extends State<TransactionSelectorScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _breathingController;
  
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();

  String _selectedCategory = 'Makanan';
  
  // 📸 VARIABEL SCANNER
  File? _selectedImage;
  bool _isScanning = false;
  final OCRService _ocrService = OCRService();

  final Map<String, IconData> _expenseCategories = {
    'Makanan': FontAwesomeIcons.burger,
    'Transportasi': FontAwesomeIcons.shuttleSpace,
    'Hiburan': FontAwesomeIcons.gamepad,
    'Tagihan': FontAwesomeIcons.fileInvoiceDollar,
    'Belanja': FontAwesomeIcons.bagShopping,
    'Kesehatan': FontAwesomeIcons.heartPulse,
    'Lainnya': FontAwesomeIcons.circleQuestion,
  };

  final Map<String, IconData> _incomeCategories = {
    'Gaji': FontAwesomeIcons.moneyBillWave,
    'Uang Bulanan': FontAwesomeIcons.calendarCheck,
    'Bonus': FontAwesomeIcons.gem,
    'Investasi': FontAwesomeIcons.chartLine,
    'Hadiah': FontAwesomeIcons.gift,
    'Lainnya': FontAwesomeIcons.circleQuestion,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _breathingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat(reverse: true);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _tabController.index == 0 ? _expenseCategories.keys.first : _incomeCategories.keys.first;
           _titleController.text = _selectedCategory;
        });
        HapticFeedback.lightImpact(); 
        SoundService.playClick();
      }
    });

    _titleFocus.addListener(() => setState(() {}));
    _amountFocus.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
       if(mounted) {
         setState(() {
            _titleController.text = _selectedCategory;
         });
       }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _titleFocus.dispose();
    _amountFocus.dispose();
    _tabController.dispose();
    _breathingController.dispose();
    _ocrService.close();
    super.dispose();
  }

  // 📸 FUNGSI SCANNER
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
        _isScanning = true;
      });

      SoundService.playClick(); 

      // Proses OCR
      double? detectedAmount = await _ocrService.scanReceipt(_selectedImage!);

      setState(() {
        _isScanning = false;
      });

      if (detectedAmount != null) {
        // Format angka hasil scan dengan titik
        final formatter = NumberFormat('#,###', 'id_ID');
        _amountController.text = formatter.format(detectedAmount.toInt());
        
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("DATA EXTRACTED: Rp ${formatter.format(detectedAmount)}")]), 
            backgroundColor: Colors.green, 
            behavior: SnackBarBehavior.floating
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ SCAN FAILED. MANUAL INPUT REQUIRED."), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 📸 PILIH SUMBER GAMBAR
  void _showImageSourceDialog(Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF0F1526).withOpacity(0.95),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: color.withOpacity(0.5))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("SELECT SOURCE", style: GoogleFonts.pressStart2p(color: color, fontSize: 12)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceBtn(Icons.camera_alt, "CAMERA", color, () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                }),
                _buildSourceBtn(Icons.image, "GALLERY", color, () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                }),
              ],
            )
          ],
        ),
      )
    );
  }

  Widget _buildSourceBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color)
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 10),
          Text(label, style: GoogleFonts.shareTechMono(color: Colors.white))
        ],
      ),
    );
  }

  void _submitData() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      HapticFeedback.heavyImpact(); 
      SoundService.playClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [Icon(Icons.error, color: Colors.white), SizedBox(width: 10), Text("SYSTEM ERROR: Data Incomplete!")]),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final enteredTitle = _titleController.text;
    double? enteredAmount = double.tryParse(_amountController.text.replaceAll('.', ''));

    if (enteredAmount == null || enteredAmount <= 0) return;

    final isExpense = _tabController.index == 0;

    final newTx = TransactionModel(
      title: enteredTitle,
      amount: enteredAmount,
      date: DateTime.now(),
      isExpense: isExpense,
      category: _selectedCategory,
      receiptPath: _selectedImage?.path, // Simpan Path Gambar
    );

    Provider.of<MoneyProvider>(context, listen: false).addTransaction(newTx);
    
    HapticFeedback.mediumImpact(); 
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    bool isExpense = _tabController.index == 0;
    Color themeColor = isExpense ? Color(0xFFFF2E63) : Color(0xFF00F5D4);

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 🌌 1. LIVING BACKGROUND
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              double scale = 1.0 + (_breathingController.value * 0.2);
              double opacity = 0.3 + (_breathingController.value * 0.2);
              
              return Stack(
                children: [
                  Positioned(
                    top: -100, right: -100,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 350, height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(color: themeColor.withOpacity(opacity), blurRadius: 150, spreadRadius: 20)
                          ],
                        ),
                      ),
                    ),
                  ),
                   Positioned(
                    bottom: -50, left: -50,
                    child: Transform.scale(
                      scale: scale * 0.9,
                      child: Container(
                        width: 250, height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor.withOpacity(0.05),
                          boxShadow: [
                            BoxShadow(color: themeColor.withOpacity(opacity * 0.8), blurRadius: 120, spreadRadius: 10)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // 2. MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("NEW ENTRY", style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 16)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white10, border: Border.all(color: Colors.white24)),
                          child: Icon(Icons.close, color: Colors.white, size: 20)
                        ),
                      )
                    ],
                  ),
                ),

                // CYBER TAB SWITCHER
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  height: 55,
                  decoration: BoxDecoration(
                    color: Color(0xFF0F1526),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 15, offset: Offset(0,5))]
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: themeColor.withOpacity(0.8), blurRadius: 20, spreadRadius: 1),
                      ]
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.shareTechMono(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.flash_on, size: 16), SizedBox(width: 8), Text("DAMAGE")])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.download_rounded, size: 16), SizedBox(width: 8), Text("LOOT")])),
                    ],
                  ),
                ),

                SizedBox(height: 25),

                // FORM
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCyberForm(true, themeColor),
                      _buildCyberForm(false, themeColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberForm(bool isExpense, Color color) {
    Map<String, IconData> categories = isExpense ? _expenseCategories : _incomeCategories;

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. INPUT ANGKA (QUANTITY) + SCANNER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel("QUANTITY", color),
              // 📸 TOMBOL SCANNER (Only for Expense usually, but available for both)
              GestureDetector(
                onTap: () => _showImageSourceDialog(color),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isScanning ? color : Colors.transparent,
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Row(
                    children: [
                      _isScanning 
                        ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Icon(Icons.qr_code_scanner, color: _isScanning ? Colors.black : color, size: 14),
                      SizedBox(width: 5),
                      Text(_isScanning ? "SCANNING..." : "SCAN STRUK", style: GoogleFonts.pressStart2p(fontSize: 8, color: _isScanning ? Colors.black : color))
                    ],
                  ),
                ),
              )
            ],
          ),
          
          SizedBox(height: 10),
          
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF16213E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _amountFocus.hasFocus ? color : Colors.white10, 
                width: _amountFocus.hasFocus ? 2.5 : 1
              ),
              boxShadow: _amountFocus.hasFocus 
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]
                : []
            ),
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()], 
              style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 36),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(FontAwesomeIcons.coins, color: color, size: 24),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 40),
                border: InputBorder.none,
                hintText: "0",
                hintStyle: TextStyle(color: Colors.white12),
                contentPadding: EdgeInsets.symmetric(vertical: 5)
              ),
            ),
          ),

          SizedBox(height: 30),

          // 2. INPUT IDENTIFIER (Auto-Fill)
          _buildLabel("IDENTIFIER", color),
          SizedBox(height: 10),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Color(0xFF16213E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _titleFocus.hasFocus ? color : Colors.white10, 
                width: _titleFocus.hasFocus ? 2.5 : 1
              ),
              boxShadow: _titleFocus.hasFocus 
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]
                : []
            ),
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Description...",
                hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                icon: Icon(Icons.edit_note, color: _titleFocus.hasFocus ? color : Colors.white54),
                 suffixIcon: _titleController.text.isNotEmpty ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () => setState(() => _titleController.clear()),
                ) : null,
              ),
            ),
          ),

          SizedBox(height: 30),

          // 3. CLASS TYPE SELECTOR
          _buildLabel("CLASS TYPE", color),
          SizedBox(height: 15),
          Wrap(
            spacing: 15, runSpacing: 15,
            children: categories.entries.map((entry) {
              bool isSelected = _selectedCategory == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = entry.key;
                    _titleController.text = entry.key;
                    _titleController.selection = TextSelection.fromPosition(TextPosition(offset: _titleController.text.length));
                  });
                  HapticFeedback.mediumImpact(); 
                  SoundService.playClick();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  transform: isSelected ? Matrix4.diagonal3Values(1.05, 1.05, 1.0) : Matrix4.identity(),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : Color(0xFF0F1526),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : Colors.white12,
                      width: isSelected ? 2.5 : 1
                    ),
                    boxShadow: isSelected 
                      ? [
                          BoxShadow(color: color.withOpacity(0.5), blurRadius: 15, spreadRadius: 1),
                        ]
                      : [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0,3))]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                         shaderCallback: (bounds) => LinearGradient(
                           colors: isSelected ? [Colors.white, color] : [Colors.white38, Colors.white38],
                           begin: Alignment.topLeft, end: Alignment.bottomRight
                         ).createShader(bounds),
                        child: Icon(entry.value, size: 16, color: Colors.white)
                      ),
                      SizedBox(width: 10),
                      Text(
                        entry.key.toUpperCase(),
                        style: GoogleFonts.shareTechMono(
                          color: isSelected ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 13
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 50),

          // 4. INITIATE BUTTON
          FadeInUp(
            duration: Duration(milliseconds: 500),
            delay: Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _submitData,
              onLongPress: () {
                 HapticFeedback.heavyImpact(); 
              },
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.5)],
                    stops: [0.2, 1.0],
                    begin: Alignment.topLeft, end: Alignment.bottomRight
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.6), blurRadius: 25, offset: Offset(0,8), spreadRadius: 2),
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Pulse(
                      infinite: true, duration: Duration(seconds: 2),
                      child: Icon(isExpense ? FontAwesomeIcons.burst : FontAwesomeIcons.rocket, color: Colors.white, size: 22)
                    ),
                    SizedBox(width: 15),
                    Text(
                      "INITIATE ${isExpense ? 'ATTACK' : 'PROTOCOL'}", 
                      style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 20, letterSpacing: 3)
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 15),
          Center(child: Opacity(opacity: 0.6, child: Text("/// PRESS TO EXECUTE SEQUENCE ///", style: GoogleFonts.shareTechMono(color: color, fontSize: 10, letterSpacing: 2)))),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.label_important_outline, color: color.withOpacity(0.7), size: 14),
        SizedBox(width: 5),
        Text(text, style: GoogleFonts.pressStart2p(color: color.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }
}

// 🔢 FORMATTER RUPIAH (Auto Titik)
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