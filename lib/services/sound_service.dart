import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  // 1. Suara Uang Masuk (Loot)
  static Future<void> playIncome() async {
    await _player.stop(); // Hentikan suara sebelumnya jika ada
    await _player.play(AssetSource('sounds/coin.mp3'));
  }

  // 2. Suara Uang Keluar (Damage)
  static Future<void> playExpense() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/laser.mp3'));
  }

  // 3. Suara Level Up (Victory)
  static Future<void> playLevelUp() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/levelup.mp3'));
  }

  // 4. Suara Klik UI (Interaction)
  static Future<void> playClick() async {
    // Untuk klik, kita buat player baru agar bisa tumpang tindih (spam click)
    final clickPlayer = AudioPlayer();
    await clickPlayer.play(AssetSource('sounds/click.mp3'));
    // Player akan otomatis dibuang oleh Garbage Collector setelah selesai
  }
}