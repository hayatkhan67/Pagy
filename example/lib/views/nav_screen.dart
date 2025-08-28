import 'package:flutter/material.dart';

import 'anime_screen.dart';
import 'anime_screen_with_state.dart';
import 'check_interceptor.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagy Example')),

      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          AnimeScreenTest(),
          AnimeScreenWithInterceptor(),
        ],
      ),
      //  _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        height: 70,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Anime',
          ),
          NavigationDestination(
            icon: Icon(Icons.privacy_tip_outlined),
            selectedIcon: Icon(Icons.privacy_tip),
            label: 'Privacy',
          ),
        ],
      ),
    );
  }
}
