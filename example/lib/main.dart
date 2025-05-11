import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

import 'views/nav_screen.dart';

void main() {
  PagyConfig().initialize(
    baseUrl: "https://pug-elegant-jennet.ngrok-free.app/",
    pageKey: 'page',
    limitKey: 'limit',
  );
  runApp(const PagyExampleApp());
}

class PagyExampleApp extends StatelessWidget {
  const PagyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagy Example',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorSchemeSeed: Colors.deepPurple,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(fontSize: 14),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
