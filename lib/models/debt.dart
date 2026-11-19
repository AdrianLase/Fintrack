import 'package:hive/hive.dart';

part 'debt.g.dart'; // Jangan lupa jalankan build_runner nanti

@HiveType(typeId: 1) // Gunakan typeId 1 karena 0 sudah dipakai Transaction
class DebtModel extends HiveObject {
  @HiveField(0)
  final String name; // Nama orangnya (Target Bounty)

  @HiveField(1)
  final double amount; // Jumlah Uang

  @HiveField(2)
  final DateTime dueDate; // Tanggal Jatuh Tempo

  @HiveField(3)
  final bool isLent; // True = Kita meminjamkan (Piutang), False = Kita berhutang

  @HiveField(4)
  bool isPaid; // Status Lunas

  DebtModel({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.isLent,
    this.isPaid = false,
  });
}