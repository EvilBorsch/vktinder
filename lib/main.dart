import 'dart:math';
import 'package:flutter/material.dart';

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

class HomeScreen extends StatefulWidget {
  final SettingsController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _cards = [];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateCards();
  }

  void _generateCards() {
    _cards.clear();
    for (int i = 0; i < 5; i++) {
      final randomWord = 'Random #${_rand.nextInt(1000)}';
      _cards.add(
        '$randomWord + ${widget.controller.vkToken} + ${widget.controller.defaultMessage}',
      );
    }
    setState(() {});
  }

  Future<void> _showSwipeDialog() async {
    // Create a TextEditingController with value2 as its initial text
    final inputController = TextEditingController(
      text: widget.controller.defaultMessage,
    );
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Карточка снята со стека'),
          content: TextField(
            controller: inputController,
            decoration: const InputDecoration(
              labelText: 'Введите что-нибудь',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void _removeTopCard() {
    if (_cards.isNotEmpty) {
      _cards.removeAt(0);
    }
    if (_cards.isEmpty) {
      _generateCards();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display the first settings field in a read-only TextField
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            readOnly: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Значение (поле 1)',
            ),
            controller: TextEditingController(text: widget.controller.vkToken),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(_cards.length, (index) {
              final cardIndex = _cards.length - 1 - index; // top card is last
              final cardText = _cards[cardIndex];
              return Dismissible(
                key: ValueKey(cardText),
                direction: DismissDirection.horizontal,
                resizeDuration: null,
                onDismissed: (dir) async {
                  _removeTopCard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Свайп прошел успешно')),
                  );
                  // Show the popup with a TextField, pre-filled with value2
                  await _showSwipeDialog();
                },
                child: CardWidget(text: cardText),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// One card occupying nearly the entire screen, with a margin
class CardWidget extends StatelessWidget {
  final String text;
  const CardWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox.expand(
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
