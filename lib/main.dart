import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; 

import 'models/transaction.dart';
import 'models/debt.dart'; 

import 'providers/money_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Hive.initFlutter();
  
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(DebtModelAdapter()); 
  
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<DebtModel>('debts');             
  await Hive.openBox<double>('budgets');              
  await Hive.openBox('raids'); // 👈 BOX BARU UNTUK RAID BOSS

  await initializeDateFormatting('id_ID', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoneyProvider()),
      ],
      child: MaterialApp(
        title: 'FinTrack RPG',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark, 
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Color(0xFF1A1A2E), 
          useMaterial3: true,
          fontFamily: 'Poppins', 
        ),
        home: DashboardScreen(),
      ),
    );
  }
}