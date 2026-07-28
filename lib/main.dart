import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: VelouraApp()));
}

/// Root application widget for Veloura.
class VelouraApp extends StatelessWidget {
  const VelouraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veloura',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4D6D),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF120B16),
        useMaterial3: true,
      ),
      home: const Scaffold(),
    );
  }
}
