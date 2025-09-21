import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagy/pagy.dart';

import 'interceptor.dart';
import 'views/nav_screen.dart';

void main() {
  PagyConfig().initialize(
    // 🌐 Your base API URL
    baseUrl: "https://pagy-backend-ten.vercel.app/api/",
    // 📩 The key your API uses to receive the current page number
    // 👉 For example: "page", "currentPage", "p", etc.
    pageKey: 'page',

    // 📩 The key your API uses to receive the number of items per page
    // 👉 For example: "limit", "perPage", "pageSize", etc.
    limitKey: 'limit',

    // 🐞 Show API logs in the console when debugging using Log Interceptor (optional)
    apiLogs: false,

    // 🔀 How your API expects pagination data to be sent
    // 👉 Use `queryParams` if it's sent in the URL (e.g. ?page=1)
    // 👉 Use `body` if it's sent inside the request body
    paginationMode: PaginationPayloadMode.queryParams,
    // customLogger: (message, {name}) {
    //   debugPrint('here test ${name ?? '[Pagy]'} $message');
    // },
    interceptor: DioInterceptor(
      onTokenBlacklisted: () {
        // Handle token blacklisted scenario
        log('Token is blacklisted');
      },
    ),

    // 🔁 How far from the bottom before fetching more (in pixels)
    scrollOffset: 200,
  );

  runApp(const ProviderScope(child: PagyExampleApp()));
}

class PagyExampleApp extends StatelessWidget {
  const PagyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagy Example',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
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
