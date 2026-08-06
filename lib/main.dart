import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/roster_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RosterService.reloadEmergencyRosters();

  runApp(const OperationRosterApp());
}

class OperationRosterApp extends StatelessWidget {
  const OperationRosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Operation Duty Roster',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),

      home: const HomeScreen(),
    );
  }
}