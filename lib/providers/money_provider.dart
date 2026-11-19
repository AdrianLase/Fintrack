import 'dart:math'; // Wajib untuk fungsi max()
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../services/sound_service.dart';

class MoneyProvider with ChangeNotifier {
  // 💾 AKSES DATABASE HIVE
  Box<TransactionModel> _box = Hive.box<TransactionModel>('transactions');
  Box<DebtModel> _debtBox = Hive.box<DebtModel>('debts');
  Box<double> _budgetBox = Hive.box<double>('budgets');
  Box _raidBox = Hive.box('raids');

  // 🕵️‍♂️ STEALTH MODE
  bool _isStealthMode = false;
  bool get isStealthMode => _isStealthMode;

  void toggleStealthMode() {
    _isStealthMode = !_isStealthMode;
    SoundService.playClick();
    notifyListeners();
  }

  // 🌾 AUTO-FARM LIST
  List<String> farmingTargets = [
    'Listrik / Token', 'Air PDAM', 'Kuota Internet', 
    'WiFi / Indihome', 'Laundry', 'Tagihan Lainnya'
  ];

  // 📋 GETTERS DATA UTAMA
  List<TransactionModel> get transactions => _box.values.toList();
  List<DebtModel> get debts => _debtBox.values.toList();

  // 💰 HITUNG SALDO
  double get totalBalance {
    double income = 0;
    double expense = 0;
    for (var item in _box.values) {
      if (item.isExpense) expense += item.amount;
      else income += item.amount;
    }
    return income - expense;
  }

  double get totalIncome => _box.values.where((e) => !e.isExpense).fold(0, (sum, item) => sum + item.amount);
  double get totalExpense => _box.values.where((e) => e.isExpense).fold(0, (sum, item) => sum + item.amount);

  // ✨ CRUD TRANSAKSI
  void addTransaction(TransactionModel transaction) {
    _box.add(transaction);

    if (transaction.isExpense) {
      SoundService.playExpense(); 
    } else {
      SoundService.playIncome();
    }

    if (transactions.length % 10 == 0) {
       Future.delayed(Duration(milliseconds: 600), () {
         SoundService.playLevelUp();
       });
    }

    notifyListeners();
  }

  void deleteTransaction(int index) {
    _box.deleteAt(index);
    notifyListeners();
  }

  // ☠️ CRUD HUTANG (BOUNTY)
  void addDebt(DebtModel debt) {
    _debtBox.add(debt);
    SoundService.playIncome();
    notifyListeners();
  }

  void toggleDebtPaid(int index) {
    final debt = _debtBox.getAt(index);
    if (debt != null) {
      debt.isPaid = !debt.isPaid;
      debt.save();
      SoundService.playClick();
      notifyListeners();
    }
  }

  void deleteDebt(int index) {
    _debtBox.deleteAt(index);
    notifyListeners();
  }

  // 🤖 AUTO-FARM LOGIC
  void triggerAutoFarm(String title, double amount, String category) {
    final newTx = TransactionModel(
      title: "Auto-Farm: $title",
      amount: amount,
      date: DateTime.now(),
      isExpense: true,
      category: category,
    );
    addTransaction(newTx);
  }

  // 📊 STATS
  Map<String, double> calculateCategoryStats() {
    Map<String, double> stats = {};
    for (var tx in _box.values) {
      if (stats.containsKey(tx.category)) {
        stats[tx.category] = stats[tx.category]! + tx.amount;
      } else {
        stats[tx.category] = tx.amount;
      }
    }
    return stats;
  }

  // 🛡️ SHIELD (BUDGET)
  void setCategoryBudget(String category, double amount) {
    _budgetBox.put(category, amount);
    notifyListeners();
  }

  double getCategoryBudget(String category) {
    return _budgetBox.get(category) ?? 0;
  }

  double getCategoryExpense(String category) {
    return _box.values
        .where((tx) => tx.isExpense && tx.category == category)
        .fold(0, (sum, item) => sum + item.amount);
  }

  // 👾 RAID BOSS
  Map<dynamic, dynamic>? get activeRaid => _raidBox.get('active');

  void summonBoss(String name, double hp) {
    _raidBox.put('active', {
      'name': name,
      'max_hp': hp,
      'current_hp': hp,
      'level': (hp / 1000000).ceil(),
    });
    SoundService.playLevelUp();
    notifyListeners();
  }

  void attackBoss(double damage) {
    if (activeRaid == null) return;

    final newTx = TransactionModel(
      title: "⚔️ Attack: ${activeRaid!['name']}",
      amount: damage,
      date: DateTime.now(),
      isExpense: true, 
      category: 'Lainnya', 
    );
    addTransaction(newTx);

    Map<dynamic, dynamic> bossData = Map.from(activeRaid!);
    bossData['current_hp'] = bossData['current_hp'] - damage;

    if (bossData['current_hp'] <= 0) {
      bossData['current_hp'] = 0.0;
      SoundService.playLevelUp();
    }

    _raidBox.put('active', bossData);
    notifyListeners();
  }

  void retreatBoss() {
    _raidBox.delete('active');
    notifyListeners();
  }

  // 🔮 ORACLE PREDICTION
  double get dailyBurnRate {
    if (transactions.isEmpty) return 0;
    final expenses = transactions.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) return 0;
    
    expenses.sort((a, b) => a.date.compareTo(b.date));
    final firstDate = expenses.first.date;
    final daysPassed = DateTime.now().difference(firstDate).inDays + 1;

    return totalExpense / daysPassed;
  }

  int get survivalDays {
    double burn = dailyBurnRate;
    if (burn <= 0) return 999;
    if (totalBalance <= 0) return 0;
    return (totalBalance / burn).floor();
  }

  String get oracleMessage {
    int days = survivalDays;
    if (totalBalance <= 0) return "SYSTEM FAILURE: FUNDS DEPLETED.";
    if (days > 30) return "SYSTEM STABLE. Resources sufficient.";
    if (days > 14) return "CAUTION: Spending rate normal.";
    if (days > 7) return "WARNING: Resources low ($days days left).";
    return "CRITICAL: BANKRUPTCY IMMINENT ($days DAYS)!";
  }

  Color get oracleColor {
    int days = survivalDays;
    if (totalBalance <= 0) return Colors.grey;
    if (days > 30) return Colors.greenAccent;
    if (days > 14) return Colors.cyanAccent;
    if (days > 7) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  // 🤖 N.E.O PET LOGIC
  String get petMood {
    DateTime now = DateTime.now();
    List<TransactionModel> todayTx = transactions.where((tx) => 
      tx.date.day == now.day && 
      tx.date.month == now.month && 
      tx.date.year == now.year
    ).toList();

    if (todayTx.isEmpty) return 'SLEEP';

    double todayExpense = todayTx.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amount);
    double dailyLimit = 100000; 

    if (todayExpense > dailyLimit) return 'PANIC';
    if (todayExpense > (dailyLimit * 0.5)) return 'WORRIED';
    return 'HAPPY';
  }

  String get petDialogue {
    switch (petMood) {
      case 'SLEEP': return "Zzz... System standby. Waiting for input.";
      case 'PANIC': return "SYSTEM OVERLOAD! Too much spending detected!";
      case 'WORRIED': return "Caution: Resources dropping. Maintain discipline.";
      case 'HAPPY': return "All systems nominal. Good job, Operator.";
      default: return "...";
    }
  }

  // 🎮 GAMIFICATION (XP & RANK)
  int get currentXP => transactions.length * 50;
  int get currentLevel => (currentXP / 500).floor() + 1;
  double get levelProgress {
    int xpForNextLevel = 500;
    int remainder = currentXP % xpForNextLevel;
    if (remainder == 0 && transactions.isNotEmpty) return 1.0;
    return remainder / xpForNextLevel;
  }

  String get userRank {
    int lvl = currentLevel;
    if (lvl < 2) return "Novice Saver 🐣";
    if (lvl < 5) return "Apprentice 🛡️";
    if (lvl < 10) return "Money Hunter 🏹";
    if (lvl < 20) return "Wealth Wizard 🧙‍♂️";
    return "Sultan Tycoon 👑";
  }

  // 📸 FITUR: PROFILE PICTURE
  String? get profileImage => _raidBox.get('profile_image');

  void updateProfileImage(String path) {
    _raidBox.put('profile_image', path);
    notifyListeners();
  }

  // 🆔 FITUR: USER NAME (IDENTITY)
  String get userName => _raidBox.get('user_name') ?? "OPERATOR"; // Default name

  void updateUserName(String name) {
    _raidBox.put('user_name', name);
    notifyListeners();
  }

  // 🏆 30 ACHIEVEMENTS (FINAL LIST)
  List<Map<String, dynamic>> get allAchievements {
    // Helper Data
    int txCount = transactions.length;
    int foodCount = transactions.where((t) => t.category == 'Makanan').length;
    int transportCount = transactions.where((t) => t.category == 'Transportasi').length;
    int incomeCount = transactions.where((t) => !t.isExpense).length;
    
    double maxExpense = 0.0;
    if (transactions.isNotEmpty) {
      var expenses = transactions.where((t) => t.isExpense);
      if (expenses.isNotEmpty) {
        maxExpense = expenses.map((t) => t.amount).reduce(max);
      }
    }

    bool hasBudget = _budgetBox.isNotEmpty;
    bool hasDebt = debts.isNotEmpty;
    bool hasPaidDebt = debts.any((d) => d.isPaid);

    return [
      // 🥉 TIER 1: NOVICE (COMMON)
      // FIX: Mengganti Icons.foot_print menjadi Icons.directions_walk
      {'id': '1', 'title': 'First Step', 'desc': 'Catat transaksi pertamamu.', 'icon': Icons.directions_walk, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': txCount >= 1},
      {'id': '2', 'title': 'Budgeting 101', 'desc': 'Buat setidaknya 1 Shield Budget.', 'icon': Icons.shield_outlined, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': hasBudget},
      {'id': '3', 'title': 'Foodie', 'desc': 'Catat 5 transaksi Makanan.', 'icon': Icons.fastfood, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': foodCount >= 5},
      {'id': '4', 'title': 'Commuter', 'desc': 'Catat 5 transaksi Transportasi.', 'icon': Icons.directions_bus, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': transportCount >= 5},
      {'id': '5', 'title': 'Payday', 'desc': 'Catat 1 Pemasukan (Income).', 'icon': Icons.attach_money, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': incomeCount >= 1},
      {'id': '6', 'title': 'Night Owl', 'desc': 'Catat transaksi di malam hari (> 22:00).', 'icon': Icons.nights_stay, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': transactions.any((t) => t.date.hour >= 22)},
      {'id': '7', 'title': 'Early Bird', 'desc': 'Catat transaksi di pagi hari (< 06:00).', 'icon': Icons.wb_sunny, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': transactions.any((t) => t.date.hour < 6)},
      {'id': '8', 'title': 'Weekend Warrior', 'desc': 'Bertransaksi di hari Sabtu/Minggu.', 'icon': Icons.weekend, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': transactions.any((t) => t.date.weekday >= 6)},
      {'id': '9', 'title': 'Debtor', 'desc': 'Catat 1 Hutang di Bounty Board.', 'icon': Icons.money_off, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': hasDebt},
      {'id': '10', 'title': 'Small Spender', 'desc': 'Pengeluaran di bawah Rp 10.000.', 'icon': Icons.local_offer, 'rarity': 'COMMON', 'color': Colors.grey, 'unlocked': transactions.any((t) => t.isExpense && t.amount < 10000)},

      // 🥈 TIER 2: ADEPT (RARE)
      {'id': '11', 'title': 'Consistency', 'desc': 'Mencapai 20 total transaksi.', 'icon': Icons.repeat, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': txCount >= 20},
      {'id': '12', 'title': 'Gluttony', 'desc': 'Mencapai 20 transaksi Makanan.', 'icon': FontAwesomeIcons.burger, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': foodCount >= 20},
      {'id': '13', 'title': 'Traveler', 'desc': 'Mencapai 20 transaksi Transportasi.', 'icon': FontAwesomeIcons.plane, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': transportCount >= 20},
      {'id': '14', 'title': 'Debt Collector', 'desc': 'Tandai 1 hutang sebagai LUNAS.', 'icon': Icons.check_circle, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': hasPaidDebt},
      {'id': '15', 'title': 'Big Spender', 'desc': 'Satu transaksi > Rp 500.000.', 'icon': Icons.shopping_bag, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': maxExpense >= 500000},
      {'id': '16', 'title': 'Safe Zone', 'desc': 'Saldo di atas Rp 1.000.000.', 'icon': Icons.savings, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': totalBalance >= 1000000},
      {'id': '17', 'title': 'Scanner', 'desc': 'Gunakan fitur Scan Struk (OCR).', 'icon': Icons.qr_code_scanner, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': transactions.any((t) => t.receiptPath != null)},
      {'id': '18', 'title': 'Auto Farmer', 'desc': 'Gunakan fitur Auto-Farm.', 'icon': Icons.agriculture, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': transactions.any((t) => t.title.contains("Auto-Farm"))},
      {'id': '19', 'title': 'Raid Beginner', 'desc': 'Summon 1 Raid Boss.', 'icon': FontAwesomeIcons.dragon, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': _raidBox.isNotEmpty},
      {'id': '20', 'title': 'Survivor', 'desc': 'Saldo positif tapi < Rp 50.000.', 'icon': Icons.heart_broken, 'rarity': 'RARE', 'color': Colors.cyanAccent, 'unlocked': totalBalance > 0 && totalBalance < 50000},

      // 🥇 TIER 3: VETERAN (EPIC)
      {'id': '21', 'title': 'Data Hoarder', 'desc': 'Mencapai 50 total transaksi.', 'icon': Icons.storage, 'rarity': 'EPIC', 'color': Colors.purpleAccent, 'unlocked': txCount >= 50},
      {'id': '22', 'title': 'Boss Slayer', 'desc': 'Kalahkan Raid Boss (HP 0).', 'icon': FontAwesomeIcons.skull, 'rarity': 'EPIC', 'color': Colors.purpleAccent, 'unlocked': activeRaid != null && activeRaid!['current_hp'] <= 0},
      {'id': '23', 'title': 'The Leviathan', 'desc': 'Satu transaksi > Rp 2.000.000.', 'icon': FontAwesomeIcons.hippo, 'rarity': 'EPIC', 'color': Colors.purpleAccent, 'unlocked': maxExpense >= 2000000},
      {'id': '24', 'title': 'Wealthy', 'desc': 'Saldo di atas Rp 5.000.000.', 'icon': Icons.diamond, 'rarity': 'EPIC', 'color': Colors.purpleAccent, 'unlocked': totalBalance >= 5000000},
      {'id': '25', 'title': 'Banker', 'desc': 'Catat 10 Pemasukan.', 'icon': FontAwesomeIcons.buildingColumns, 'rarity': 'EPIC', 'color': Colors.purpleAccent, 'unlocked': incomeCount >= 10},

      // 👑 TIER 4: GODLIKE (LEGENDARY)
      {'id': '26', 'title': 'Centurion', 'desc': 'Mencapai 100 total transaksi.', 'icon': FontAwesomeIcons.crown, 'rarity': 'LEGENDARY', 'color': Colors.amber, 'unlocked': txCount >= 100},
      {'id': '27', 'title': 'Sultan', 'desc': 'Saldo di atas Rp 10.000.000.', 'icon': FontAwesomeIcons.moneyBill1, 'rarity': 'LEGENDARY', 'color': Colors.amber, 'unlocked': totalBalance >= 10000000},
      {'id': '28', 'title': 'Bounty King', 'desc': 'Lunasi 5 Hutang.', 'icon': FontAwesomeIcons.clipboardCheck, 'rarity': 'LEGENDARY', 'color': Colors.amber, 'unlocked': debts.where((d) => d.isPaid).length >= 5},
      {'id': '29', 'title': 'Iron Wall', 'desc': 'Miliki 5 Shield Budget aktif.', 'icon': FontAwesomeIcons.shieldHalved, 'rarity': 'LEGENDARY', 'color': Colors.amber, 'unlocked': _budgetBox.length >= 5},
      {'id': '30', 'title': 'THE ONE', 'desc': 'Buka semua achievement di atas.', 'icon': FontAwesomeIcons.trophy, 'rarity': 'LEGENDARY', 'color': Colors.amber, 'unlocked': false}, 
    ];
  }
}