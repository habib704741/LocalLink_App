import 'package:flutter/material.dart';
import 'data/repository.dart';
import 'screens/dashboard_screen.dart';

void main() {
  const String phoneIp = "";

  final repository = ApiRepository(phoneIp);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final LocalLinkRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalLink Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: DashboardScreen(repository: repository),
    );
  }
}
