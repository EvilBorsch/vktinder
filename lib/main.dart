import 'package:flutter/material.dart';
import 'package:vktinder/settings_controller.dart';
import 'package:vktinder/home_screen.dart';
import 'package:vktinder/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load settings once before running the app
  final controller = await SettingsController.load();
  runApp(MyApp(controller: controller));
}

class MyApp extends StatefulWidget {
  final SettingsController controller;
  const MyApp({super.key, required this.controller});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// This State listens to changes in [widget.controller] and updates the app.
class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSettingsChanged);
    // Once loaded, we can mark the app as ready
    _isLoading = false;
  }

  void _onSettingsChanged() {
    // Force a rebuild whenever the controller notifies listeners.
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSettingsChanged);
    super.dispose();
  }

  ThemeMode _getThemeMode() {
    switch (widget.controller.selectedTheme) {
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
      debugShowCheckedModeBanner: false,
      title: 'VK tinder',
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

      // Since the entire app is forced to rebuild when settings change,
      // we merely need to pass the controller through to the pages:
      home: MainPage(controller: widget.controller),
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
      ..add(SettingsScreen(controller: widget.controller));
    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
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
