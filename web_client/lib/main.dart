import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/presentation/connection_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalLink - Web Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ConnectionScreen(),
    );
  }
}
