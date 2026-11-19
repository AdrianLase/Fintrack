import 'dart:io';
import 'dart:ui'; // Untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter & Haptic
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart'; 
import '../models/transaction.dart';
import '../providers/money_provider.dart';
import '../services/ocr_service.dart';
import '../services/sound_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool isExpenseMode;

  const AddTransactionScreen({Key? key, required this.isExpenseMode}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();

  late String _selectedCategory;
  File? _selectedImage;

  bool _isScanning = false;
  final OCRService _ocrService = OCRService();
  
  late AnimationController _breathingController;

  // 🎨 MAPPING KATEGORI
  final Map<String, Map<String, dynamic>> _categoryData = {
    'Makanan': {'icon': FontAwesomeIcons.burger, 'color': Colors.orangeAccent},
    'Transportasi': {'icon': FontAwesomeIcons.shuttleSpace, 'color': Colors.cyanAccent},
    'Hiburan': {'icon': FontAwesomeIcons.gamepad, 'color': Colors.purpleAccent},
    'Tagihan': {'icon': FontAwesomeIcons.fileInvoiceDollar, 'color': Colors.redAccent},
    'Belanja': {'icon': FontAwesomeIcons.bagShopping, 'color': Colors.pinkAccent},
    'Kesehatan': {'icon': FontAwesomeIcons.heartPulse, 'color': Colors.greenAccent},
    'Gaji': {'icon': FontAwesomeIcons.coins, 'color': Colors.amber},
    'Bonus': {'icon': FontAwesomeIcons.gem, 'color': Colors.tealAccent},
    'Lainnya': {'icon': FontAwesomeIcons.ghost, 'color': Colors.grey},
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.isExpenseMode ? 'Makanan' : 'Gaji';
    
    // Animasi Background & Scanner Bernafas
    _breathingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _titleFocus.addListener(() => setState(() {}));
    _amountFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ocrService.close();
    _titleController.dispose();
    _amountController.dispose();
    _titleFocus.dispose();
    _amountFocus.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  Color get _themeColor => widget.isExpenseMode ? Color(0xFFFF2E63) : Color(0xFF00E0FF); 

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
        _isScanning = true;
      });

      SoundService.playClick(); 

      double? detectedAmount = await _ocrService.scanReceipt(_selectedImage!);

      setState(() {
        _isScanning = false;
      });

      if (detectedAmount != null) {
        final formatter = NumberFormat('#,###', 'id_ID');
        _amountController.text = formatter.format(detectedAmount.toInt());
        
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✨ DATA DECODED: Rp ${formatter.format(detectedAmount)}"), backgroundColor: _themeColor, behavior: SnackBarBehavior.floating),
        );
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ SCAN FAILED. MANUAL INPUT REQUIRED."), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _submitData() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }

    String cleanAmount = _amountController.text.replaceAll('.', ''); 
    final enteredAmount = double.parse(cleanAmount);
    
    if (enteredAmount <= 0) return;

    final newTransaction = TransactionModel(
      title: _titleController.text,
      amount: enteredAmount,
      date: _selectedDate,
      isExpense: widget.isExpenseMode,
      category: _selectedCategory,
      receiptPath: _selectedImage?.path,
    );

    Provider.of<MoneyProvider>(context, listen: false).addTransaction(newTransaction);
    HapticFeedback.mediumImpact();
    SoundService.playExpense();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E), 
      body: Stack(
        children: [
          // 🌌 1. LIVING BACKGROUND
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              double scale = 1.0 + (_breathingController.value * 0.1);
              return Positioned(
                top: -100, right: -100,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 400, height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _themeColor.withOpacity(0.1),
                      boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.3), blurRadius: 100, spreadRadius: 10)],
                    ),
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: _themeColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        widget.isExpenseMode ? "DAMAGE REPORT" : "LOOT CLAIM",
                        style: GoogleFonts.pressStart2p(color: _themeColor, fontSize: 14),
                      ),
                      SizedBox(width: 40), 
                    ],
                  ),
                  
                  SizedBox(height: 30),

                  // 🔹 2. AMOUNT INPUT
                  Text("VALUE POINTS", style: GoogleFonts.shareTechMono(color: _themeColor, fontSize: 12, letterSpacing: 2)),
                  SizedBox(height: 10),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _amountFocus.hasFocus ? _themeColor : Colors.white10, 
                        width: _amountFocus.hasFocus ? 2 : 1
                      ),
                      boxShadow: _amountFocus.hasFocus 
                        ? [BoxShadow(color: _themeColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 1)]
                        : [],
                    ),
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: GoogleFonts.blackOpsOne(fontSize: 40, color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("Rp ", style: GoogleFonts.vt323(fontSize: 24, color: _themeColor)),
                        ),
                        border: InputBorder.none,
                        hintText: "0",
                        hintStyle: TextStyle(color: Colors.white12),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // 🔹 3. QUEST TITLE
                  _buildInputLabel("QUEST TITLE"),
                  _buildGamingTextField(
                    controller: _titleController, 
                    focusNode: _titleFocus,
                    hint: widget.isExpenseMode ? "Ex: Health Potion (Coffee)" : "Ex: Boss Drop (Bonus)", 
                    icon: Icons.edit_note
                  ),

                  SizedBox(height: 25),

                  // 🔹 4. CATEGORY SELECTOR
                  _buildInputLabel("SELECT CLASS"),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 90, 
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      children: _categoryData.keys.map((cat) {
                        bool isSelected = _selectedCategory == cat;
                        Color catColor = _categoryData[cat]!['color'];
                        IconData catIcon = _categoryData[cat]!['icon'];

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            HapticFeedback.selectionClick();
                            SoundService.playClick();
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            width: 75,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? catColor.withOpacity(0.2) : Color(0xFF0F1526),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected ? catColor : Colors.white10,
                                width: isSelected ? 2 : 1
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: catColor.withOpacity(0.4), blurRadius: 10)] : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(catIcon, color: isSelected ? catColor : Colors.white38, size: 20),
                                SizedBox(height: 5),
                                Text(
                                  cat,
                                  style: GoogleFonts.shareTechMono(
                                    color: isSelected ? Colors.white : Colors.white38,
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 25),

                  // 🔹 5. TIMESTAMP
                  _buildInputLabel("TIMESTAMP"),
                  _buildGamingDatePicker(context),

                  SizedBox(height: 30),

                  // 📸 6. CYBER SCANNER HUD (FIXED ANIMATION)
                  _buildInputLabel("EVIDENCE SCANNER"),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isScanning ? null : () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => _buildImagePickerOption(),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _breathingController,
                      builder: (ctx, child) {
                        return Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFF0F1526),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              // Efek border berdenyut saat scanning
                              color: _isScanning 
                                  ? _themeColor.withOpacity(0.5 + (_breathingController.value * 0.5)) 
                                  : (_selectedImage != null ? Colors.greenAccent : Colors.white10), 
                              width: _isScanning ? 2 : 1
                            ),
                            image: (_selectedImage != null && !_isScanning)
                                ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover, opacity: 0.4)
                                : null,
                            boxShadow: _isScanning 
                                ? [BoxShadow(color: _themeColor.withOpacity(0.2), blurRadius: 15 * _breathingController.value)] 
                                : []
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Grid Pattern
                              if (_selectedImage == null)
                                Opacity(opacity: 0.05, child: Image.network("https://www.transparenttextures.com/patterns/graphy.png", repeat: ImageRepeat.repeat)),
                              
                              // Scanner Line Animation
                              if (_isScanning)
                                FadeInDown(
                                  duration: Duration(seconds: 1),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, _themeColor.withOpacity(0.5), Colors.transparent],
                                        stops: [0.0, 0.5, 1.0]
                                      )
                                    ),
                                  ),
                                ),

                              // Content Text
                              _isScanning
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("ANALYZING ARTIFACT...", style: GoogleFonts.shareTechMono(color: _themeColor, fontSize: 12)),
                                    ],
                                  )
                                : _selectedImage == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_scanner, size: 40, color: _themeColor.withOpacity(0.5)),
                                          SizedBox(height: 5),
                                          Text("TAP TO SCAN RECEIPT", style: GoogleFonts.shareTechMono(color: Colors.white24)),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                                          Text("DATA ACQUIRED", style: GoogleFonts.blackOpsOne(color: Colors.greenAccent, fontSize: 14)),
                                        ],
                                      ),
                            ],
                          ),
                        );
                      }
                    ),
                  ),

                  SizedBox(height: 40),

                  // 🔹 7. SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                      onPressed: _isScanning ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColor,
                        shadowColor: _themeColor,
                        elevation: 15,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.isExpenseMode ? Icons.bolt : Icons.download, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            widget.isExpenseMode ? "CONFIRM DAMAGE" : "CONFIRM LOOT",
                            style: GoogleFonts.blackOpsOne(fontSize: 16, color: Colors.white, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) => Text(label, style: GoogleFonts.shareTechMono(fontSize: 10, color: _themeColor, letterSpacing: 1));
  
  Widget _buildGamingTextField({required TextEditingController controller, required FocusNode focusNode, required String hint, required IconData icon}) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Color(0xFF16213E), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(
          color: focusNode.hasFocus ? _themeColor : Colors.white10,
          width: focusNode.hasFocus ? 1.5 : 1
        ),
        boxShadow: focusNode.hasFocus ? [BoxShadow(color: _themeColor.withOpacity(0.2), blurRadius: 10)] : []
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint, 
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white24),
          prefixIcon: Icon(icon, color: focusNode.hasFocus ? _themeColor : Colors.white24),
          border: InputBorder.none, 
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGamingDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final picked = await showDatePicker(
          context: context, 
          initialDate: _selectedDate, 
          firstDate: DateTime(2020), 
          lastDate: DateTime.now(), 
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(primary: _themeColor, onPrimary: Colors.white, surface: Color(0xFF16213E)),
              dialogBackgroundColor: Color(0xFF0F1526)
            ), 
            child: child!
          )
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        margin: EdgeInsets.only(top: 8), 
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          Icon(Icons.calendar_month, color: _themeColor), 
          SizedBox(width: 15), 
          Text(DateFormat('d MMMM yyyy').format(_selectedDate), style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16))
        ]),
      ),
    );
  }

  Widget _buildImagePickerOption() {
    return Container(
      padding: EdgeInsets.all(24), height: 220,
      decoration: BoxDecoration(
        color: Color(0xFF0F1526).withOpacity(0.95), 
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: _themeColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.1), blurRadius: 20)]
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          SizedBox(height: 20),
          Text("SELECT INPUT SOURCE", style: GoogleFonts.pressStart2p(fontSize: 10, color: _themeColor)), 
          SizedBox(height: 30), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
            children: [
              _buildPickerBtn(Icons.camera_alt, "CAMERA", Colors.cyanAccent, () => _pickImage(ImageSource.camera)), 
              _buildPickerBtn(Icons.image, "GALLERY", Colors.purpleAccent, () => _pickImage(ImageSource.gallery))
            ]
          )
        ]
      ),
    );
  }

  Widget _buildPickerBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16), 
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), 
              shape: BoxShape.circle, 
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]
            ), 
            child: Icon(icon, color: color, size: 30)
          ), 
          SizedBox(height: 10), 
          Text(label, style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold))
        ]
      ),
    );
  }
}

// 🔢 FORMATTER RUPIAH (Auto Dot)
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