import 'package:flutter/material.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/presentation/pages/home_screen.dart';
import 'package:vktinder/presentation/pages/settings_screen.dart';

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

/// This State listens to changes in [widget.controller] and updates the app accordingly.
class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Define the pages for bottom navigation
    _pages = [
      HomeScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];
  }

  ThemeMode _getThemeMode() {
    switch (widget.controller.settings.selectedTheme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VK tinder',
      debugShowCheckedModeBanner: false,
      themeMode: _getThemeMode(),
      theme: lightThemeColors(),
      darkTheme: darkThemeColors(),
      home: Scaffold(
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
      ),
    );
  }

  ThemeData darkThemeColors() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[900],
      cardTheme: CardTheme(
        color: Colors.grey[850],
        shadowColor: Colors.black54,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }

  ThemeData lightThemeColors() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[100],
      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.grey[350],
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
}
