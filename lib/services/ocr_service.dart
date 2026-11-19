import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // Inisialisasi pengenalan teks
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<double?> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    
    try {
      // 1. Proses Gambar jadi Teks
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // 2. Cari angka total di struk
      return _parseTotalAmount(recognizedText);
    } catch (e) {
      print("Error reading text: $e");
      return null;
    }
  }

  // 🕵️‍♂️ Logika Detektif mencari angka 'Total'
  double? _parseTotalAmount(RecognizedText recognizedText) {
    double maxAmount = 0.0;
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text.toLowerCase();
        
        // Bersihkan teks: Hapus huruf, simbol, sisakan angka saja
        // Contoh: "Rp 50.000" -> "50000"
        String cleanText = text.replaceAll(RegExp(r'[^0-9]'), ''); 
        
        if (cleanText.isNotEmpty) {
          try {
            double value = double.parse(cleanText);
            
            // FILTER LOGIKA:
            // 1. Abaikan jika angkanya terlalu panjang (kemungkinan No. HP / ID Transaksi) -> misal > 12 digit
            // 2. Abaikan jika terlalu kecil (< 100 perak)
            // 3. Ambil angka TERBESAR yang rasional (biasanya Total ada di paling bawah dan nominal paling besar)
            
            if (value > maxAmount && cleanText.length < 12) { 
               maxAmount = value;
            }
          } catch (e) {
            // Skip jika error parsing
          }
        }
      }
    }

    return maxAmount > 0 ? maxAmount : null;
  }

  void close() {
    textRecognizer.close();
  }
}