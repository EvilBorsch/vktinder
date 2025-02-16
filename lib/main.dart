import 'package:flutter/material.dart';
import 'package:vktinder/home_screen.dart';
import 'package:vktinder/settings_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SettingsController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _controller = await SettingsController.load();
    setState(() => _isLoading = false);
  }

  ThemeMode _getThemeMode() {
    switch (_controller.selectedTheme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'Beautiful Full-Screen Cards with Popup',
      // Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        cardTheme: CardTheme(
          color: Colors.white,
          shadowColor: Colors.grey[350],
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
          centerTitle: true,
          elevation: 2,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      // Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        cardTheme: CardTheme(
          color: Colors.grey[850],
          shadowColor: Colors.black54,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          color: Colors.grey[850],
          centerTitle: true,
          elevation: 2,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[850],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey[500],
          type: BottomNavigationBarType.fixed,
        ),
      ),
      themeMode: _getThemeMode(),
      home: MainPage(controller: _controller),
    );
  }
}

class MainPage extends StatefulWidget {
  final SettingsController controller;

  const MainPage({super.key, required this.controller});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> _pages = [];
  bool _isInitialized = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setUpPages();
  }

  void _setUpPages() {
    _pages
      ..add(HomeScreen(controller: widget.controller))
      ..add(
        SettingsScreen(
          controller: widget.controller,
          onThemeChange: _onThemeChange,
        ),
      );
    setState(() => _isInitialized = true);
  }

  void _onThemeChange() {
    // Force rebuild to apply the updated theme
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beautiful Full-Screen Cards with Popup'),
      ),
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
