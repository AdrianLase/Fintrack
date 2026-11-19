import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final bool isExpense;

  @HiveField(4)
  final String category;

  @HiveField(5) // 🆕 Field Baru: Path Foto Struk
  final String? receiptPath;

  TransactionModel({
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
    this.receiptPath, // 🆕 Tambahkan di constructor
  });
}