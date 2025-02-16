import 'package:flutter/material.dart';
import 'package:vktinder/home_screen.dart';

import 'package:vktinder/settings_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full-Screen Cards with Popup',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}

/// Manages two text settings, stored in SharedPreferences

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late SettingsController _controller;
  bool _isLoading = true;

  final List<Widget> _pages = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = await SettingsController.load();
    _pages
      ..add(HomeScreen(controller: _controller))
      ..add(SettingsScreen(controller: _controller));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Full-Screen Cards with Popup')),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
